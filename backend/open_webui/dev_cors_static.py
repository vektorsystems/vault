"""
Development middleware for CORS on static files.
This module provides a middleware that adds CORS headers to static file responses
for local development when frontend and backend are on different ports.
"""

import os
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi import FastAPI


def add_static_cors_middleware(app: FastAPI, allowed_origins):
    """
    Add CORS middleware for static files to the FastAPI app.
    This middleware is only active in development environments.
    
    Args:
        app: The FastAPI application instance
        allowed_origins: List of allowed origins for CORS
    """
    # Only add middleware in development
    if os.environ.get("RAG_ENV", "production") == "production":
        return  # Skip in production
    
    class StaticCORSMiddleware(BaseHTTPMiddleware):
        async def dispatch(self, request, call_next):
            response = await call_next(request)
            if request.url.path.startswith("/static/"):
                # Get the origin from the request headers
                origin = request.headers.get("origin")
                if origin:
                    # Check if the origin is in the allowed origins
                    if "*" in allowed_origins or origin in allowed_origins:
                        response.headers["Access-Control-Allow-Origin"] = origin
                        response.headers["Vary"] = "Origin"
            return response

    app.add_middleware(StaticCORSMiddleware) 