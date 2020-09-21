package utils

import (
	"crypto/hmac"
	"crypto/md5"
	"encoding/hex"
	uuid "github.com/satori/go.uuid"
	"strings"
)

func IsStringEmpty(str string) bool {
	return strings.Trim(str, " ") == ""
}

func Hmac(key string, data string) string {
	hmacHash := hmac.New(md5.New, []byte(key))
	hmacHash.Write([]byte(data))
	return hex.EncodeToString(hmacHash.Sum([]byte("")))
}

func GetUUID() (string, error) {
	u := uuid.NewV4()
	return u.String(), nil
}
