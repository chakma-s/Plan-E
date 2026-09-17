"""
Plan-E: Regional Policy & Multi-Jurisdiction Compliance Engine.

Architected to allow Plan-E to run in any country/region in the world
without struggling against local consumer protection laws, tax rules, or privacy policies.

Key Global Compliance Capabilities:
1. Dynamic Tax Strategies (VAT-inclusive in EU/UK/Australia vs. sales tax added at checkout in US/Canada).
2. Dynamic Currencies (USD, EUR, GBP, INR, BDT, AED, JPY, CAD, AUD, etc.).
3. Statutory Cancellation Windows (Cooling-off periods: US 24h, EU 14-day distance selling exceptions, etc.).
4. Privacy & Consent Frameworks (GDPR in EU, CCPA in California, DPDP in India).
5. Regional Legal Disclosures rendered dynamically into consumer interfaces.
"""

from typing import Dict, Optional
from decimal import Decimal, ROUND_HALF_UP
from pydantic import BaseModel, Field


class RegionalPolicy(BaseModel):
    region_code: str = Field(description="ISO 3166-1 alpha-2 country code or region code (e.g. US, EU, GB, IN, BD, AE, GLOBAL)")
    region_name: str
    currency: str = Field(default="USD", description="ISO 4217 currency code")
    currency_symbol: str = Field(default="$")
    tax_rate_percentage: float = Field(default=8.5, description="Regional lodging tax or VAT percentage")
    tax_display_mode: str = Field(default="exclusive", description="'inclusive' (VAT included in list price) or 'exclusive' (tax added at checkout)")
    platform_fee_percentage: float = Field(default=5.0, description="Platform service commission percentage")
    cooling_off_hours: int = Field(default=24, description="Statutory full-refund cooling-off period in hours")
    requires_explicit_consent: bool = Field(default=True, description="Whether GDPR/DPDP explicit consent checkboxes are required")
    privacy_framework: str = Field(default="GDPR-Ready", description="Active regional privacy framework (e.g. GDPR, CCPA, DPDP)")
    disclosures: Dict[str, str] = Field(default_factory=dict, description="Mandatory localized legal disclosures")


# Built-in Regional Presets
REGIONAL_PRESETS: Dict[str, RegionalPolicy] = {
    "GLOBAL": RegionalPolicy(
        region_code="GLOBAL",
        region_name="Global Default Jurisdiction",
        currency="USD",
        currency_symbol="$",
        tax_rate_percentage=8.5,
        tax_display_mode="exclusive",
        platform_fee_percentage=5.0,
        cooling_off_hours=24,
        requires_explicit_consent=True,
        privacy_framework="Global Standard (GDPR-Aligned)",
        disclosures={
            "pricing": "Prices exclude local lodging taxes which are computed at checkout.",
            "cancellation": "Free cancellation available within 24 hours of booking unless check-in is within 48 hours.",
            "privacy": "Personal data is processed in accordance with our Global Privacy Policy.",
        },
    ),
    "US": RegionalPolicy(
        region_code="US",
        region_name="United States",
        currency="USD",
        currency_symbol="$",
        tax_rate_percentage=8.5,
        tax_display_mode="exclusive",
        platform_fee_percentage=5.0,
        cooling_off_hours=24,
        requires_explicit_consent=False,
        privacy_framework="CCPA / State Hospitality Statutes",
        disclosures={
            "pricing": "Room rates exclude mandatory state/local lodging tax and resort fees.",
            "cancellation": "Cancellations made within 24 hours of booking qualify for a 100% full refund.",
            "privacy": "California residents: see Do Not Sell My Personal Information rights under CCPA.",
        },
    ),
    "EU": RegionalPolicy(
        region_code="EU",
        region_name="European Union",
        currency="EUR",
        currency_symbol="€",
        tax_rate_percentage=19.0,
        tax_display_mode="inclusive",
        platform_fee_percentage=5.0,
        cooling_off_hours=48,
        requires_explicit_consent=True,
        privacy_framework="GDPR / DAC7 Directive",
        disclosures={
            "pricing": "All prices shown are inclusive of mandatory Value Added Tax (VAT) under EU regulations.",
            "cancellation": "Statutory booking conditions apply. Full refund available up to 48 hours after reservation.",
            "privacy": "Your data is secured strictly within GDPR compliance standards with full data portability rights.",
            "dac7": "Host revenue transactions are reported in accordance with EU DAC7 reporting standards.",
        },
    ),
    "GB": RegionalPolicy(
        region_code="GB",
        region_name="United Kingdom",
        currency="GBP",
        currency_symbol="£",
        tax_rate_percentage=20.0,
        tax_display_mode="inclusive",
        platform_fee_percentage=5.0,
        cooling_off_hours=48,
        requires_explicit_consent=True,
        privacy_framework="UK GDPR / Consumer Rights Act",
        disclosures={
            "pricing": "Prices shown include standard 20% UK VAT.",
            "cancellation": "Complies with the Consumer Rights Act 2015 for digital travel intermediation.",
            "privacy": "Data protected under the UK Data Protection Act 2018.",
        },
    ),
    "IN": RegionalPolicy(
        region_code="IN",
        region_name="India",
        currency="INR",
        currency_symbol="₹",
        tax_rate_percentage=12.0,
        tax_display_mode="inclusive",
        platform_fee_percentage=5.0,
        cooling_off_hours=24,
        requires_explicit_consent=True,
        privacy_framework="Digital Personal Data Protection (DPDP) Act",
        disclosures={
            "pricing": "Room charges subject to standard Goods & Services Tax (GST) as per Ministry of Finance rules.",
            "cancellation": "Cancellation refunds processed within statutory payment reconciliation cycles.",
            "privacy": "Data processing adheres to India Digital Personal Data Protection Act 2023.",
        },
    ),
    "BD": RegionalPolicy(
        region_code="BD",
        region_name="Bangladesh",
        currency="BDT",
        currency_symbol="৳",
        tax_rate_percentage=15.0,
        tax_display_mode="inclusive",
        platform_fee_percentage=4.5,
        cooling_off_hours=24,
        requires_explicit_consent=True,
        privacy_framework="National Data Protection Regulations",
        disclosures={
            "pricing": "All rates display standard 15% VAT per National Board of Revenue tourism guidelines.",
            "cancellation": "Cancellations subject to vendor-specific accommodation policies.",
            "privacy": "Customer records maintained under local electronic transactions governance.",
        },
    ),
    "AE": RegionalPolicy(
        region_code="AE",
        region_name="United Arab Emirates",
        currency="AED",
        currency_symbol="د.إ",
        tax_rate_percentage=5.0,
        tax_display_mode="exclusive",
        platform_fee_percentage=5.0,
        cooling_off_hours=24,
        requires_explicit_consent=False,
        privacy_framework="UAE Federal Decree-Law on Personal Data Protection",
        disclosures={
            "pricing": "5% VAT included. Tourism Dirham Fee payable directly upon hotel check-in.",
            "cancellation": "Standard free cancellation window applies up to 24 hours post-booking.",
            "privacy": "Personal data handled under UAE Federal Personal Data Protection Law.",
        },
    ),
}


class RegionalPolicyManager:
    """Singleton manager for resolving and configuring regional policies."""

    _active_region_override: Optional[str] = None

    @classmethod
    def set_active_region(cls, region_code: str):
        code = region_code.upper()
        if code in REGIONAL_PRESETS:
            cls._active_region_override = code

    @classmethod
    def get_policy(cls, region_code: Optional[str] = None) -> RegionalPolicy:
        """
        Resolve the applicable policy.
        Precedence:
        1. Explicit argument `region_code`
        2. Configured override
        3. GLOBAL default
        """
        target = region_code or cls._active_region_override or "GLOBAL"
        target_code = target.upper()
        return REGIONAL_PRESETS.get(target_code, REGIONAL_PRESETS["GLOBAL"])

    @classmethod
    def calculate_totals(
        cls,
        subtotal: Decimal,
        guide_fee: Decimal = Decimal("0.00"),
        region_code: Optional[str] = None,
    ) -> Dict[str, Decimal]:
        """
        Calculate taxes and platform fees according to regional policy.
        Handles both 'inclusive' and 'exclusive' tax mechanisms.
        """
        policy = cls.get_policy(region_code)
        tax_pct = Decimal(str(policy.tax_rate_percentage)) / Decimal("100")
        fee_pct = Decimal(str(policy.platform_fee_percentage)) / Decimal("100")

        taxable_subtotal = subtotal + guide_fee
        platform_fee = (taxable_subtotal * fee_pct).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        if policy.tax_display_mode == "inclusive":
            tax_amount = (taxable_subtotal * (tax_pct / (Decimal("1") + tax_pct))).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
            total_amount = taxable_subtotal + platform_fee
        else:
            tax_amount = (taxable_subtotal * tax_pct).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            total_amount = taxable_subtotal + platform_fee + tax_amount

        return {
            "room_subtotal": subtotal,
            "guide_subtotal": guide_fee,
            "platform_fee": platform_fee,
            "tax_amount": tax_amount,
            "total_amount": total_amount,
        }
