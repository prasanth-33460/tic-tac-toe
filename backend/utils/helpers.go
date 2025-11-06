package utils

import (
	"encoding/json"
	"fmt"
)

// JsonMarshal is a helper function to marshal data to JSON with error handling
func JsonMarshal(v interface{}) ([]byte, error) {
	data, err := json.Marshal(v)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal JSON: %v", err)
	}
	return data, nil
}

// JsonUnmarshal is a helper function to unmarshal JSON data with error handling
func JsonUnmarshal(data []byte, v interface{}) error {
	if err := json.Unmarshal(data, v); err != nil {
		return fmt.Errorf("failed to unmarshal JSON: %v", err)
	}
	return nil
}

// ValidateString checks if a string is within the allowed length
func ValidateString(s string, minLen, maxLen int) error {
	if len(s) < minLen || len(s) > maxLen {
		return fmt.Errorf("string length must be between %d and %d characters", minLen, maxLen)
	}
	return nil
}

// ContainsString checks if a string is present in a slice of strings
func ContainsString(slice []string, str string) bool {
	for _, s := range slice {
		if s == str {
			return true
		}
	}
	return false
}

// FilterStrings returns a new slice containing only strings that pass the filter function
func FilterStrings(slice []string, filter func(string) bool) []string {
	result := make([]string, 0, len(slice))
	for _, s := range slice {
		if filter(s) {
			result = append(result, s)
		}
	}
	return result
}
