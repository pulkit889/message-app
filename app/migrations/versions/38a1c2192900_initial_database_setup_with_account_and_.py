"""Initial database setup with Account and Message models

Revision ID: 38a1c2192900
Revises: 
Create Date: 2024-09-21 11:42:05.256158

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '38a1c2192900'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('message',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('account_id', sa.String(length=50), nullable=False),
    sa.Column('message_id', sa.String(length=36), nullable=False),
    sa.Column('sender_number', sa.String(length=15), nullable=False),
    sa.Column('receiver_number', sa.String(length=15), nullable=False),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('message_id')
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('message')
    # ### end Alembic commands ###
