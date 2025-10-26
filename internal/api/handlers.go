package api

import (
	"fmt"
	"io"
	"net/http"
	"strconv"

	"github.com/adilg123/file-compression-decompression-tool/internal/compression"
	"github.com/gin-gonic/gin"
)

const maxFileSize = 50 * 1024 * 1024 // 50MB

// CompressRequest represents the compression request payload
type CompressRequest struct {
	Algorithm string `form:"algorithm" binding:"required"`
	BType     *int   `form:"btype,omitempty"`
	BFinal    *int   `form:"bfinal,omitempty"`
}

// DecompressRequest represents the decompression request payload
type DecompressRequest struct {
	Algorithm string `form:"algorithm" binding:"required"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error   string `json:"error"`
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// SuccessResponse represents a successful operation response
type SuccessResponse struct {
	Message          string   `json:"message"`
	Algorithm        string   `json:"algorithm"`
	OriginalSize     int      `json:"original_size"`
	ProcessedSize    int      `json:"processed_size"`
	CompressionRatio *float64 `json:"compression_ratio,omitempty"`
	Filename         string   `json:"filename"`
}

// HandleCompress handles file compression requests
func HandleCompress(c *gin.Context) {
	var req CompressRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Code:    http.StatusBadRequest,
			Message: err.Error(),
		})
		return
	}

	// Validate algorithm
	if !compression.IsValidAlgorithm(req.Algorithm) {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid algorithm",
			Code:    http.StatusBadRequest,
			Message: fmt.Sprintf("Supported algorithms: %v", compression.GetSupportedAlgorithms()),
		})
		return
	}

	// Get uploaded file
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "File upload error",
			Code:    http.StatusBadRequest,
			Message: "No file provided or file upload failed",
		})
		return
	}
	defer file.Close()

	// Check file size
	if header.Size > maxFileSize {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "File too large",
			Code:    http.StatusBadRequest,
			Message: fmt.Sprintf("Maximum file size is %d bytes", maxFileSize),
		})
		return
	}

	// Read file content
	fileContent, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "File read error",
			Code:    http.StatusInternalServerError,
			Message: "Failed to read uploaded file",
		})
		return
	}

	// Prepare compression options
	options := compression.Options{
		Algorithm: req.Algorithm,
	}

	if req.BType != nil {
		options.BType = uint32(*req.BType)
	}
	if req.BFinal != nil {
		options.BFinal = uint32(*req.BFinal)
	}

	// Compress the file
	compressedData, stats, err := compression.Compress(fileContent, options)
	_ = stats // TODO: use stats (original size, processed size, ratio) or remove from return
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Compression failed",
			Code:    http.StatusInternalServerError,
			Message: err.Error(),
		})
		return
	}

	// Set response headers for file download
	filename := fmt.Sprintf("%s_compressed.%s", getBaseFilename(header.Filename), getExtensionForAlgorithm(req.Algorithm))
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Header("Content-Type", "application/octet-stream")
	c.Header("Content-Length", strconv.Itoa(len(compressedData)))

	// Send compressed data
	c.Data(http.StatusOK, "application/octet-stream", compressedData)
}

// HandleDecompress handles file decompression requests
func HandleDecompress(c *gin.Context) {
	var req DecompressRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Code:    http.StatusBadRequest,
			Message: err.Error(),
		})
		return
	}

	// Validate algorithm
	if !compression.IsValidAlgorithm(req.Algorithm) {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid algorithm",
			Code:    http.StatusBadRequest,
			Message: fmt.Sprintf("Supported algorithms: %v", compression.GetSupportedAlgorithms()),
		})
		return
	}

	// Get uploaded file
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "File upload error",
			Code:    http.StatusBadRequest,
			Message: "No file provided or file upload failed",
		})
		return
	}
	defer file.Close()

	// Check file size
	if header.Size > maxFileSize {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "File too large",
			Code:    http.StatusBadRequest,
			Message: fmt.Sprintf("Maximum file size is %d bytes", maxFileSize),
		})
		return
	}

	// Read file content
	fileContent, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "File read error",
			Code:    http.StatusInternalServerError,
			Message: "Failed to read uploaded file",
		})
		return
	}

	// Decompress the file
	decompressedData, stats, err := compression.Decompress(fileContent, compression.Options{
		Algorithm: req.Algorithm,
	})
	_ = stats // TODO: use stats (original size, processed size, ratio) or remove from return
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Decompression failed",
			Code:    http.StatusInternalServerError,
			Message: err.Error(),
		})
		return
	}

	// Set response headers for file download
	filename := fmt.Sprintf("%s_decompressed.txt", getBaseFilename(header.Filename))
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Header("Content-Type", "text/plain")
	c.Header("Content-Length", strconv.Itoa(len(decompressedData)))

	// Send decompressed data
	c.Data(http.StatusOK, "text/plain", decompressedData)
}

// HandleInfo provides information about supported algorithms
func HandleInfo(c *gin.Context) {
	info := map[string]interface{}{
		"service": "File Compression/Decompression Tool",
		"version": "1.0.0",
		"algorithms": map[string]interface{}{
			"supported": compression.GetSupportedAlgorithms(),
			"descriptions": map[string]string{
				"huffman": "Huffman coding - lossless data compression using variable-length codes",
				"lzss":    "Lempel-Ziv-Storer-Szymanski - dictionary-based compression",
				"flate":   "DEFLATE - combination of LZ77 and Huffman coding",
				"gzip":    "GZIP - wrapper around DEFLATE with headers and checksums",
			},
		},
		"limits": map[string]interface{}{
			"max_file_size": fmt.Sprintf("%d bytes (%.1f MB)", maxFileSize, float64(maxFileSize)/(1024*1024)),
		},
		"endpoints": map[string]interface{}{
			"compress":   "POST /compress - Upload file for compression",
			"decompress": "POST /decompress - Upload file for decompression",
			"info":       "GET /info - Get service information",
			"health":     "GET /health - Health check",
		},
	}

	c.JSON(http.StatusOK, info)
}

// HandleHealth provides a simple health check endpoint
func HandleHealth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "compression-service",
	})
}

// Helper functions
func getBaseFilename(filename string) string {
	if filename == "" {
		return "file"
	}

	// Remove extension
	for i := len(filename) - 1; i >= 0; i-- {
		if filename[i] == '.' {
			return filename[:i]
		}
	}
	return filename
}

func getExtensionForAlgorithm(algorithm string) string {
	extensions := map[string]string{
		"huffman": "huff",
		"lzss":    "lzss",
		"flate":   "flate",
		"gzip":    "gz",
	}

	if ext, exists := extensions[algorithm]; exists {
		return ext
	}
	return "compressed"
}
