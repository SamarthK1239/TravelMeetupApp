"""Travel plan model."""

from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class TravelPlan(Base):
    """Travel plan model for user trips."""
    
    __tablename__ = "travel_plans"
    
    # Primary Key
    plan_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Foreign Key
    user_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Location Information
    city = Column(String(100), nullable=False, index=True)
    country = Column(String(100), nullable=False)
    
    # Date Information
    start_date = Column(Date, nullable=False, index=True)
    end_date = Column(Date, nullable=False, index=True)
    
    # Trip Details
    purpose = Column(String(50), nullable=True)  # 'vacation', 'business', 'visiting', 'other'
    notes = Column(String(1000), nullable=True)
    is_public = Column(Integer, default=1, nullable=False)  # 1 = public, 0 = private
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="travel_plans")
    
    def __repr__(self):
        return f"<TravelPlan(id={self.plan_id}, user={self.user_id}, city='{self.city}', dates={self.start_date} to {self.end_date})>"
