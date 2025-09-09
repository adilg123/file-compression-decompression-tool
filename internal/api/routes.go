package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// SetupRoutes configures all API routes
func SetupRoutes(router *gin.Engine) {
	// CORS middleware for public API access
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		
		c.Next()
	})

	// Health check endpoint
	router.GET("/health", HandleHealth)
	
	// Service information endpoint
	router.GET("/info", HandleInfo)
	router.GET("/", HandleInfo) // Root endpoint shows info
	
	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		v1.POST("/compress", HandleCompress)
		v1.POST("/decompress", HandleDecompress)
		v1.GET("/info", HandleInfo)
		v1.GET("/health", HandleHealth)
	}
	
	// Legacy routes for backward compatibility
	router.POST("/compress", HandleCompress)
	router.POST("/decompress", HandleDecompress)
}