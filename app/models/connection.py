"""Connection model for friend relationships."""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Connection(Base):
    """Connection/friendship model between users."""
    
    __tablename__ = "connections"
    
    # Primary Key
    connection_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Foreign Keys
    user1_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    user2_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Connection Status
    status = Column(
        String(20),
        nullable=False,
        default='pending',
        index=True
    )  # 'pending', 'accepted', 'blocked'
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), nullable=True)
    
    # Relationships
    user1 = relationship("User", foreign_keys=[user1_id], back_populates="connections_initiated")
    user2 = relationship("User", foreign_keys=[user2_id], back_populates="connections_received")
    
    # Constraints
    __table_args__ = (
        CheckConstraint('user1_id < user2_id', name='check_user_order'),
        CheckConstraint(
            "status IN ('pending', 'accepted', 'blocked')",
            name='check_connection_status'
        ),
    )
    
    def __repr__(self):
        return f"<Connection(id={self.connection_id}, user1={self.user1_id}, user2={self.user2_id}, status='{self.status}')>"
