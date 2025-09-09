package compression

import (
	"fmt"
	"io"

	"github.com/adilg123/file-compression-decompression-tool/internal/compression/algorithms/flate"
	"github.com/adilg123/file-compression-decompression-tool/internal/compression/algorithms/gzip"
	"github.com/adilg123/file-compression-decompression-tool/internal/compression/algorithms/huffman"
	"github.com/adilg123/file-compression-decompression-tool/internal/compression/algorithms/lzss"
)

// SupportedAlgorithms contains all supported compression algorithms
var SupportedAlgorithms = []string{
	"huffman",
	"lzss", 
	"flate",
	"gzip",
}

// Options contains compression/decompression options
type Options struct {
	Algorithm string
	BType     uint32 // For FLATE/GZIP
	BFinal    uint32 // For FLATE/GZIP
}

// Stats contains compression statistics
type Stats struct {
	OriginalSize     int
	ProcessedSize    int
	CompressionRatio float64
	Algorithm        string
}

// AlgorithmFactory defines the interface for compression algorithms
type AlgorithmFactory interface {
	NewCompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser)
	NewDecompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser)
}

// factoryMap maps algorithm names to their factories
var factoryMap = map[string]AlgorithmFactory{
	"huffman": &HuffmanFactory{},
	"lzss":    &LZSSFactory{},
	"flate":   &FlateFactory{},
	"gzip":    &GzipFactory{},
}

// Factory implementations
type HuffmanFactory struct{}
func (f *HuffmanFactory) NewCompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	return huffman.NewCompressionReaderAndWriter()
}
func (f *HuffmanFactory) NewDecompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	return huffman.NewDecompressionReaderAndWriter()
}

type LZSSFactory struct{}
func (f *LZSSFactory) NewCompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	return lzss.NewCompressionReaderAndWriter(4096, 4096)
}
func (f *LZSSFactory) NewDecompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	return lzss.NewDecompressionReaderAndWriter()
}

type FlateFactory struct{}
func (f *FlateFactory) NewCompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	btype := options.BType
	if btype == 0 {
		btype = 2 // Default to dynamic Huffman
	}
	return flate.NewCompressionReaderAndWriter(btype, options.BFinal)
}
func (f *FlateFactory) NewDecompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	return flate.NewDecompressionReaderAndWriter()
}

type GzipFactory struct{}
func (f *GzipFactory) NewCompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	btype := options.BType
	if btype == 0 {
		btype = 2 // Default to dynamic Huffman
	}
	flateReader, flateWriter := flate.NewCompressionReaderAndWriter(btype, options.BFinal)
	return gzip.NewCompressionReaderAndWriter(flateReader, flateWriter)
}
func (f *GzipFactory) NewDecompressionReaderAndWriter(options Options) (io.ReadCloser, io.WriteCloser) {
	flateReader, flateWriter := flate.NewDecompressionReaderAndWriter()
	return gzip.NewDecompressionReaderAndWriter(flateReader, flateWriter)
}

// IsValidAlgorithm checks if the provided algorithm is supported
func IsValidAlgorithm(algorithm string) bool {
	_, exists := factoryMap[algorithm]
	return exists
}

// GetSupportedAlgorithms returns a list of supported algorithms
func GetSupportedAlgorithms() []string {
	return append([]string{}, SupportedAlgorithms...)
}

// Compress compresses data using the specified algorithm
func Compress(data []byte, options Options) ([]byte, *Stats, error) {
	if !IsValidAlgorithm(options.Algorithm) {
		return nil, nil, fmt.Errorf("unsupported algorithm: %s", options.Algorithm)
	}

	factory := factoryMap[options.Algorithm]
	reader, writer := factory.NewCompressionReaderAndWriter(options)
	
	// Perform compression
	compressedData, err := processData(data, reader, writer)
	if err != nil {
		return nil, nil, fmt.Errorf("compression failed: %w", err)
	}

	// Calculate statistics
	stats := &Stats{
		OriginalSize:     len(data),
		ProcessedSize:    len(compressedData),
		Algorithm:        options.Algorithm,
	}
	
	if len(data) > 0 {
		stats.CompressionRatio = float64(len(compressedData)) / float64(len(data)) * 100
	}

	return compressedData, stats, nil
}

// Decompress decompresses data using the specified algorithm
func Decompress(data []byte, options Options) ([]byte, *Stats, error) {
	if !IsValidAlgorithm(options.Algorithm) {
		return nil, nil, fmt.Errorf("unsupported algorithm: %s", options.Algorithm)
	}

	factory := factoryMap[options.Algorithm]
	reader, writer := factory.NewDecompressionReaderAndWriter(options)
	
	// Perform decompression
	decompressedData, err := processData(data, reader, writer)
	if err != nil {
		return nil, nil, fmt.Errorf("decompression failed: %w", err)
	}

	// Calculate statistics
	stats := &Stats{
		OriginalSize:     len(data),
		ProcessedSize:    len(decompressedData),
		Algorithm:        options.Algorithm,
	}
	
	if len(data) > 0 {
		stats.CompressionRatio = float64(len(data)) / float64(len(decompressedData)) * 100
	}

	return decompressedData, stats, nil
}

// processData handles the common pattern of writing to writer and reading from reader
func processData(inputData []byte, reader io.ReadCloser, writer io.WriteCloser) ([]byte, error) {
	defer reader.Close()
	defer writer.Close()

	// Channel to collect the result
	resultCh := make(chan []byte, 1)
	errorCh := make(chan error, 1)

	// Start reading in a goroutine
	go func() {
		defer close(resultCh)
		defer close(errorCh)
		
		// Read all data from reader
		data, err := io.ReadAll(reader)
		if err != nil {
			errorCh <- err
			return
		}
		resultCh <- data
	}()

	// Write input data and close writer
	if _, err := writer.Write(inputData); err != nil {
		return nil, fmt.Errorf("failed to write data: %w", err)
	}
	
	if err := writer.Close(); err != nil {
		return nil, fmt.Errorf("failed to close writer: %w", err)
	}

	// Wait for result or error
	select {
	case err := <-errorCh:
		if err != nil {
			return nil, err
		}
	case result := <-resultCh:
		return result, nil
	}

	return nil, fmt.Errorf("unexpected error during processing")
}