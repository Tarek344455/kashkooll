"""Data models for MCP client results."""
from dataclasses import dataclass, field
from typing import Any, Optional, List, Dict
from datetime import datetime


@dataclass
class ScrapeResult:
    """Result from web scraping."""
    url: str
    markdown: str = ""
    html: str = ""
    text: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    links: List[str] = field(default_factory=list)
    images: List[str] = field(default_factory=list)
    success: bool = True
    error: Optional[str] = None
    server_used: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class SearchResult:
    """Result from web search."""
    query: str
    results: List[Dict[str, Any]] = field(default_factory=list)
    success: bool = True
    error: Optional[str] = None
    server_used: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class TranscriptResult:
    """Result from YouTube transcript."""
    video_id: str
    video_url: str
    transcript: List[Dict[str, Any]] = field(default_factory=list)
    full_text: str = ""
    language: str = "en"
    success: bool = True
    error: Optional[str] = None
    server_used: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class PDFResult:
    """Result from PDF processing."""
    source: str  # URL or file path
    text: str = ""
    pages: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)
    success: bool = True
    error: Optional[str] = None
    server_used: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class ThinkResult:
    """Result from sequential thinking."""
    steps: List[Dict[str, Any]] = field(default_factory=list)
    conclusion: str = ""
    success: bool = True
    error: Optional[str] = None
    server_used: str = ""
    timestamp: datetime = field(default_factory=datetime.now)