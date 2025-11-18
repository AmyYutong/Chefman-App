#!/usr/bin/env python3
"""
Image storage and management for Chefman Studio
Handles image upload, storage, and serving
"""

import os
import uuid
from pathlib import Path
from typing import Optional
from fastapi import UploadFile, HTTPException
from PIL import Image
import aiofiles

# Configuration
UPLOAD_DIR = "uploads"
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
THUMBNAIL_SIZE = (300, 300)

class ImageStorage:
    def __init__(self, upload_dir: str = UPLOAD_DIR):
        self.upload_dir = Path(upload_dir)
        self.upload_dir.mkdir(exist_ok=True)
        
        # Create subdirectories
        (self.upload_dir / "recipes").mkdir(exist_ok=True)
        (self.upload_dir / "users").mkdir(exist_ok=True)
        (self.upload_dir / "thumbnails").mkdir(exist_ok=True)
    
    def _validate_file(self, file: UploadFile) -> None:
        """Validate uploaded file"""
        if not file.filename:
            raise HTTPException(status_code=400, detail="No filename provided")
        
        # Check file extension
        file_ext = Path(file.filename).suffix.lower()
        if file_ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400, 
                detail=f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
            )
        
        # Check file size
        if hasattr(file, 'size') and file.size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400, 
                detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB"
            )
    
    async def save_image(self, file: UploadFile, category: str = "recipes") -> dict:
        """
        Save uploaded image and create thumbnail
        
        Args:
            file: Uploaded file
            category: Category of image (recipes, users, etc.)
            
        Returns:
            dict: Image information including URLs
        """
        self._validate_file(file)
        
        # Generate unique filename
        file_ext = Path(file.filename).suffix.lower()
        unique_id = str(uuid.uuid4())
        filename = f"{unique_id}{file_ext}"
        
        # Define paths
        category_dir = self.upload_dir / category
        category_dir.mkdir(exist_ok=True)
        
        file_path = category_dir / filename
        thumbnail_path = self.upload_dir / "thumbnails" / f"thumb_{filename}"
        
        try:
            # Read file content
            content = await file.read()
            
            # Check file size after reading
            if len(content) > MAX_FILE_SIZE:
                raise HTTPException(
                    status_code=400, 
                    detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB"
                )
            
            # Save original image
            async with aiofiles.open(file_path, 'wb') as f:
                await f.write(content)
            
            # Create thumbnail
            await self._create_thumbnail(content, thumbnail_path)
            
            # Return image information
            return {
                "id": unique_id,
                "filename": filename,
                "original_url": f"/images/{category}/{filename}",
                "thumbnail_url": f"/images/thumbnails/thumb_{filename}",
                "size": len(content),
                "category": category
            }
            
        except Exception as e:
            # Clean up on error
            if file_path.exists():
                file_path.unlink()
            if thumbnail_path.exists():
                thumbnail_path.unlink()
            raise HTTPException(status_code=500, detail=f"Failed to save image: {str(e)}")
    
    async def _create_thumbnail(self, image_content: bytes, thumbnail_path: Path) -> None:
        """Create thumbnail from image content"""
        try:
            # Open image from bytes
            image = Image.open(io.BytesIO(image_content))
            
            # Convert to RGB if necessary
            if image.mode in ("RGBA", "P"):
                image = image.convert("RGB")
            
            # Create thumbnail
            image.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)
            
            # Save thumbnail
            image.save(thumbnail_path, "JPEG", quality=85)
            
        except Exception as e:
            print(f"Failed to create thumbnail: {e}")
            # Don't raise exception for thumbnail creation failure
    
    def get_image_path(self, category: str, filename: str) -> Path:
        """Get full path to image file"""
        return self.upload_dir / category / filename
    
    def get_thumbnail_path(self, filename: str) -> Path:
        """Get full path to thumbnail file"""
        return self.upload_dir / "thumbnails" / f"thumb_{filename}"
    
    def delete_image(self, category: str, filename: str) -> bool:
        """Delete image and its thumbnail"""
        try:
            # Delete original image
            image_path = self.get_image_path(category, filename)
            if image_path.exists():
                image_path.unlink()
            
            # Delete thumbnail
            thumbnail_path = self.get_thumbnail_path(filename)
            if thumbnail_path.exists():
                thumbnail_path.unlink()
            
            return True
        except Exception as e:
            print(f"Failed to delete image {filename}: {e}")
            return False

# Global instance
image_storage = ImageStorage()

# Import io for image processing
import io

