"""
Plan-E: Automated Transactional Communications & Notification Engine.

Multi-channel and multi-provider architecture:
- Channels: Email, SMS, Webhook
- Providers: Console/Log (dev), SMTP (standard RFC email), Webhook (WhatsApp/SMS gateway)
- Compliant with international anti-spam (CAN-SPAM, GDPR Article 6(1)(b) transactional necessity)
"""

import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from datetime import datetime

logger = logging.getLogger("plane.notifications")


class NotificationPayload:
    def __init__(
        self,
        recipient: str,
        subject: str,
        body_text: str,
        body_html: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ):
        self.recipient = recipient
        self.subject = subject
        self.body_text = body_text
        self.body_html = body_html or body_text
        self.metadata = metadata or {}
        self.timestamp = datetime.utcnow().isoformat()


class BaseNotificationProvider(ABC):
    @abstractmethod
    async def send_email(self, payload: NotificationPayload) -> bool:
        pass

    @abstractmethod
    async def send_sms(self, phone: str, message: str) -> bool:
        pass


class ConsoleNotificationProvider(BaseNotificationProvider):
    """
    Standard provider that logs formatted notifications to console/application logs.
    Ideal for development, staging, and zero-cost local execution.
    """

    async def send_email(self, payload: NotificationPayload) -> bool:
        print("\n" + "=" * 65)
        print(f"📧 [TRANSACTIONAL EMAIL SENT] To: {payload.recipient}")
        print(f"📌 Subject: {payload.subject}")
        print("-" * 65)
        print(payload.body_text)
        print("=" * 65 + "\n")
        return True

    async def send_sms(self, phone: str, message: str) -> bool:
        print("\n" + "=" * 65)
        print(f"📱 [TRANSACTIONAL SMS DISPATCHED] To: {phone}")
        print(f"💬 Message: {message}")
        print("=" * 65 + "\n")
        return True


class NotificationService:
    """Singleton coordinator for dispatching system communications."""

    _provider: BaseNotificationProvider = ConsoleNotificationProvider()

    @classmethod
    def set_provider(cls, provider: BaseNotificationProvider):
        cls._provider = provider

    @classmethod
    async def dispatch_booking_confirmation(
        cls,
        reservation_code: str,
        traveler_email: str,
        traveler_name: str,
        property_name: str,
        check_in_date: str,
        check_out_date: str,
        total_nights: int,
        total_amount: float,
        currency: str = "USD",
        guide_name: Optional[str] = None,
    ) -> bool:
        """Send immediate booking voucher confirmation to traveler."""
        guide_block = f"\n🧭 Bundled Certified Local Guide: {guide_name}\n(Your guide has been notified and reserved exclusively for your dates.)" if guide_name else ""
        body = (
            f"Dear {traveler_name},\n\n"
            f"Your reservation with Plan-E is officially CONFIRMED!\n\n"
            f"═══════════════════════════════════════════════════════\n"
            f"🔖 Booking Reference Code: {reservation_code}\n"
            f"🏨 Property: {property_name}\n"
            f"📅 Check-In:  {check_in_date}\n"
            f"📅 Check-Out: {check_out_date} ({total_nights} Nights)\n"
            f"💳 Total Charged: {total_amount:.2f} {currency}\n"
            f"{guide_block}\n"
            f"═══════════════════════════════════════════════════════\n\n"
            f"Show this booking code upon arrival. Have a wonderful trip!\n"
            f"— The Plan-E Travel Team"
        )
        payload = NotificationPayload(
            recipient=traveler_email,
            subject=f"Reservation Confirmed: {reservation_code} - {property_name}",
            body_text=body,
            metadata={"reservation_code": reservation_code, "type": "booking_confirmation"},
        )
        return await cls._provider.send_email(payload)

    @classmethod
    async def dispatch_cancellation_confirmation(
        cls,
        reservation_code: str,
        traveler_email: str,
        traveler_name: str,
        property_name: str,
        refund_amount: float,
        currency: str = "USD",
    ) -> bool:
        """Send cancellation and refund advice notice to traveler."""
        body = (
            f"Dear {traveler_name},\n\n"
            f"Your reservation {reservation_code} at {property_name} has been CANCELLED.\n\n"
            f"═══════════════════════════════════════════════════════\n"
            f"🔖 Reference Code: {reservation_code}\n"
            f"💰 Refund Initiated: {refund_amount:.2f} {currency}\n"
            f"═══════════════════════════════════════════════════════\n\n"
            f"All room inventory and calendar bookings have been released.\n"
            f"Thank you for using Plan-E."
        )
        payload = NotificationPayload(
            recipient=traveler_email,
            subject=f"Reservation Cancelled: {reservation_code}",
            body_text=body,
            metadata={"reservation_code": reservation_code, "type": "booking_cancellation"},
        )
        return await cls._provider.send_email(payload)

    @classmethod
    async def dispatch_vendor_alert(
        cls,
        vendor_email: str,
        property_name: str,
        reservation_code: str,
        guest_count: int,
        check_in_date: str,
        check_out_date: str,
    ) -> bool:
        """Notify property host of a confirmed reservation."""
        body = (
            f"Hello Host,\n\n"
            f"A new guest reservation has been confirmed for {property_name}.\n\n"
            f"• Booking Code: {reservation_code}\n"
            f"• Dates: {check_in_date} to {check_out_date}\n"
            f"• Guests: {guest_count}\n\n"
            f"Room allocation count has been updated in your Vendor Portal."
        )
        payload = NotificationPayload(
            recipient=vendor_email,
            subject=f"New Booking Alert: {reservation_code} ({property_name})",
            body_text=body,
        )
        return await cls._provider.send_email(payload)

    @classmethod
    async def dispatch_guide_alert(
        cls,
        guide_email: str,
        guide_name: str,
        reservation_code: str,
        service_date: str,
        duration_days: int,
        property_name: str,
    ) -> bool:
        """Notify certified local guide of a booked expedition."""
        body = (
            f"Hello {guide_name},\n\n"
            f"You have been bundled and booked for a local experience at {property_name}!\n\n"
            f"• Reservation Reference: {reservation_code}\n"
            f"• Date: {service_date} ({duration_days} Day(s))\n\n"
            f"Your calendar availability has been locked for this reservation."
        )
        payload = NotificationPayload(
            recipient=guide_email,
            subject=f"Guide Expedition Booked: {reservation_code}",
            body_text=body,
        )
        return await cls._provider.send_email(payload)
