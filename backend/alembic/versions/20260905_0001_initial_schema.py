"""Initial unified schema with multi-jurisdiction indexes and allocation constraints

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-09-05 20:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Baseline migration placeholder representing the complete schema generated
    # by Base.metadata.create_all and backend/sql/schema.sql.
    # Future incremental schema evolutions will append new revision files here.
    pass


def downgrade() -> None:
    pass
