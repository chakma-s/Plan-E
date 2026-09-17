"""
Plan-E: Pluggable Regional Payment Gateway Architecture.

Designed to allow seamless operation across any country/region in the world.
Completely decouples reservation transactions from specific payment gateway vendors.

Regional providers (e.g. bKash, Razorpay, M-Pesa, Adyen, Pix, Stripe, etc.)
can be plugged in simply by implementing the PaymentGatewayInterface.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from decimal import Decimal
from pydantic import BaseModel


class PaymentIntentResult(BaseModel):
    transaction_id: str
    status: str  # "pending", "requires_action", "authorized", "succeeded"
    amount: Decimal
    currency: str
    client_secret: Optional[str] = None
    redirect_url: Optional[str] = None
    provider: str
    metadata: Dict[str, Any] = {}


class RefundResult(BaseModel):
    refund_id: str
    transaction_id: str
    amount: Decimal
    currency: str
    status: str  # "succeeded", "pending", "failed"
    provider: str


class PaymentGatewayInterface(ABC):
    """Abstract Strategy Interface for any regional or global payment gateway."""

    @abstractmethod
    async def create_intent(
        self,
        booking_id: str,
        amount: Decimal,
        currency: str,
        customer_email: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> PaymentIntentResult:
        """Initialize a payment authorization / checkout session."""
        pass

    @abstractmethod
    async def capture_or_confirm(
        self,
        transaction_id: str,
        amount: Optional[Decimal] = None,
    ) -> PaymentIntentResult:
        """Confirm or capture authorized payment."""
        pass

    @abstractmethod
    async def process_refund(
        self,
        transaction_id: str,
        amount: Decimal,
        currency: str,
        reason: Optional[str] = None,
    ) -> RefundResult:
        """Execute a refund back to traveler in accordance with regional consumer policy."""
        pass


class MockRegionalPaymentGateway(PaymentGatewayInterface):
    """
    Standard zero-dependency mock provider.
    Enables immediate offline execution, local testing, and mock sandbox flows.
    """

    provider_name = "standard_mock"

    async def create_intent(
        self,
        booking_id: str,
        amount: Decimal,
        currency: str,
        customer_email: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> PaymentIntentResult:
        import uuid
        tx_id = f"mock_tx_{uuid.uuid4().hex[:12]}"
        return PaymentIntentResult(
            transaction_id=tx_id,
            status="succeeded",
            amount=amount,
            currency=currency,
            client_secret=f"secret_{tx_id}",
            provider=self.provider_name,
            metadata=metadata or {},
        )

    async def capture_or_confirm(
        self,
        transaction_id: str,
        amount: Optional[Decimal] = None,
    ) -> PaymentIntentResult:
        return PaymentIntentResult(
            transaction_id=transaction_id,
            status="succeeded",
            amount=amount or Decimal("0.00"),
            currency="USD",
            provider=self.provider_name,
        )

    async def process_refund(
        self,
        transaction_id: str,
        amount: Decimal,
        currency: str,
        reason: Optional[str] = None,
    ) -> RefundResult:
        import uuid
        return RefundResult(
            refund_id=f"mock_ref_{uuid.uuid4().hex[:12]}",
            transaction_id=transaction_id,
            amount=amount,
            currency=currency,
            status="succeeded",
            provider=self.provider_name,
        )


class PaymentGatewayFactory:
    """Registry and factory for dynamically resolving the active payment provider."""

    _providers: Dict[str, PaymentGatewayInterface] = {
        "mock": MockRegionalPaymentGateway(),
    }
    _active_provider_key: str = "mock"

    @classmethod
    def register_provider(cls, name: str, provider: PaymentGatewayInterface):
        """Register a custom regional payment gateway provider."""
        cls._providers[name.lower()] = provider

    @classmethod
    def set_active_provider(cls, name: str):
        key = name.lower()
        if key in cls._providers:
            cls._active_provider_key = key

    @classmethod
    def get_active_gateway(cls) -> PaymentGatewayInterface:
        return cls._providers.get(cls._active_provider_key, cls._providers["mock"])
