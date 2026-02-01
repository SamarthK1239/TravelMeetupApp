"""Notification model."""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Notification(Base):
    """Notification model for user alerts."""
    
    __tablename__ = "notifications"
    
    # Primary Key
    notification_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Foreign Key
    user_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Notification Details
    type = Column(String(50), nullable=False, index=True)  # 'connection_request', 'travel_match', 'profile_update'
    title = Column(String(200), nullable=False)
    message = Column(String(1000), nullable=False)
    
    # Status
    is_read = Column(Integer, default=0, nullable=False, index=True)  # 0 = unread, 1 = read
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Optional reference to related entity
    related_entity_type = Column(String(50), nullable=True)  # 'connection', 'travel_plan', 'user'
    related_entity_id = Column(Integer, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="notifications")
    
    def __repr__(self):
        return f"<Notification(id={self.notification_id}, user={self.user_id}, type='{self.type}', read={bool(self.is_read)})>"
