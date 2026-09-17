"""
Plan-E: Global Rate Limiting & Anti-Scraping Middleware.

Protects sensitive search, quote, and booking endpoints from automated bots,
credential stuffers, and high-frequency scraper traffic without heavy external dependencies.
"""

import time
from typing import Dict, Tuple
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response


class RateLimiter:
    """Sliding-window in-memory IP rate limiter."""

    def __init__(self, requests_per_minute: int = 120):
        self.requests_per_minute = requests_per_minute
        self.window_seconds = 60
        # Maps client_ip -> (timestamp_of_window_start, count)
        self._clients: Dict[str, Tuple[float, int]] = {}

    def is_rate_limited(self, client_ip: str) -> Tuple[bool, int, int]:
        """
        Check if client has exceeded quota.
        Returns: (is_limited: bool, remaining_requests: int, retry_after: int)
        """
        now = time.time()
        window_start, count = self._clients.get(client_ip, (now, 0))

        if now - window_start > self.window_seconds:
            # New window
            self._clients[client_ip] = (now, 1)
            return False, self.requests_per_minute - 1, 0

        if count >= self.requests_per_minute:
            retry_after = int(self.window_seconds - (now - window_start)) + 1
            return True, 0, max(1, retry_after)

        self._clients[client_ip] = (window_start, count + 1)
        remaining = max(0, self.requests_per_minute - (count + 1))
        return False, remaining, 0

    def cleanup(self):
        """Purge stale client records older than 5 minutes."""
        now = time.time()
        stale_threshold = 300
        stale_keys = [ip for ip, (start, _) in self._clients.items() if now - start > stale_threshold]
        for ip in stale_keys:
            self._clients.pop(ip, None)


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, requests_per_minute: int = 120):
        super().__init__(app)
        self.limiter = RateLimiter(requests_per_minute=requests_per_minute)
        self.exempt_prefixes = ("/static", "/favicon.ico", "/health", "/docs", "/redoc", "/openapi.json")

    async def dispatch(self, request: Request, call_next) -> Response:
        path = request.url.path

        # Bypass static files, API documentation, and health checks
        if any(path.startswith(prefix) for prefix in self.exempt_prefixes):
            return await call_next(request)

        # Identify client by CF-Connecting-IP, X-Forwarded-For, or direct client host
        client_ip = (
            request.headers.get("cf-connecting-ip")
            or request.headers.get("x-forwarded-for", "").split(",")[0].strip()
            or (request.client.host if request.client else "127.0.0.1")
        )

        is_limited, remaining, retry_after = self.limiter.is_rate_limited(client_ip)

        if is_limited:
            return JSONResponse(
                status_code=429,
                content={
                    "status": "error",
                    "code": "RATE_LIMIT_EXCEEDED",
                    "message": "Too many requests. Please slow down and try again shortly.",
                    "retry_after_seconds": retry_after,
                },
                headers={
                    "Retry-After": str(retry_after),
                    "X-RateLimit-Limit": str(self.limiter.requests_per_minute),
                    "X-RateLimit-Remaining": "0",
                },
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(self.limiter.requests_per_minute)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        return response
