"""User model."""

from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class User(Base):
    """User account model."""
    
    __tablename__ = "users"
    
    # Primary Key
    user_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Authentication
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    
    # Profile Information
    username = Column(String(50), unique=True, nullable=False, index=True)
    display_name = Column(String(100), nullable=False)
    bio = Column(String(500), nullable=True)
    profile_picture_url = Column(String(500), nullable=True)
    home_city = Column(String(100), nullable=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), nullable=True)
    last_login = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Relationships
    # Connections where this user is user1
    connections_initiated = relationship(
        "Connection",
        foreign_keys="Connection.user1_id",
        back_populates="user1",
        cascade="all, delete-orphan"
    )
    
    # Connections where this user is user2
    connections_received = relationship(
        "Connection",
        foreign_keys="Connection.user2_id",
        back_populates="user2",
        cascade="all, delete-orphan"
    )
    
    # Travel plans
    travel_plans = relationship(
        "TravelPlan",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    
    # Notifications
    notifications = relationship(
        "Notification",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<User(id={self.user_id}, username='{self.username}', email='{self.email}')>"
