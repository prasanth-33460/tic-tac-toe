package utils

import (
	"encoding/json"
	"fmt"
)

// JsonMarshal serialises v to JSON.
func JsonMarshal(v any) ([]byte, error) {
	data, err := json.Marshal(v)
	if err != nil {
		return nil, fmt.Errorf("json marshal: %w", err)
	}
	return data, nil
}

// JsonUnmarshal deserialises JSON into v.
func JsonUnmarshal(data []byte, v any) error {
	if err := json.Unmarshal(data, v); err != nil {
		return fmt.Errorf("json unmarshal: %w", err)
	}
	return nil
}

// ContainsString reports whether slice contains str.
func ContainsString(slice []string, str string) bool {
	for _, s := range slice {
		if s == str {
			return true
		}
	}
	return false
}

// FilterStrings returns a new slice containing only strings that pass the filter function.
func FilterStrings(slice []string, filter func(string) bool) []string {
	filtered := make([]string, 0, len(slice))
	for _, s := range slice {
		if filter(s) {
			filtered = append(filtered, s)
		}
	}
	return filtered
}

// Abs returns the absolute value of x.
func Abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

// ValidateString checks whether s is within the allowed length range.
func ValidateString(s string, minLen, maxLen int) error {
	if len(s) < minLen || len(s) > maxLen {
		return fmt.Errorf("string length must be between %d and %d characters", minLen, maxLen)
	}
	return nil
}
