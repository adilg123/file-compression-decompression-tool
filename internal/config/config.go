package config

import (
	"os"
)

// Config holds the application configuration
type Config struct {
	Port        string
	Environment string
	MaxFileSize int64 // in bytes
}

// Load loads configuration from environment variables with defaults
func Load() *Config {
	cfg := &Config{
		Port:        getEnv("PORT", "8080"),
		Environment: getEnv("GO_ENV", "development"),
		MaxFileSize: 50 * 1024 * 1024, // 50MB default
	}

	return cfg
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}