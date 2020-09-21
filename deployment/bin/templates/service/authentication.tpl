package service

import (
	"net/http"
	"{{ .ProjectConfig.PackageName }}/casbin"
	"{{ .ProjectConfig.PackageName }}/db"
	"{{ .ProjectConfig.PackageName }}/service/model"
	"{{ .ProjectConfig.PackageName }}/utils"
	"strconv"
)

func Authentication(userID uint64, resource string, action string, token string) (bool, error) {
        if userID == 0 || utils.IsStringEmpty(resource) || utils.IsStringEmpty(action) || utils.IsStringEmpty(token) {
		return false, model.ErrParam
	}

	httpRequest := &http.Request{Header: make(http.Header)}
	httpRequest.Header.Add("Authorization", token)
	valid, err := checkJWT(httpRequest)
	if err != nil {
		return false, err
	}

	if !valid {
		return false, model.ErrTokenInvalid
	}

	pass, err := casbin.Enforce(strconv.FormatUint(userID, 10), resource, action)
	if err != nil {
		return false, err
	}

	if !pass {
		return false, nil
	}

	return true, nil
}

func GetAndUpdateAccessToken(username string, password string) (string, error) {
	if utils.IsStringEmpty(username) || utils.IsStringEmpty(password) {
		return "", model.ErrParam
	}

	user, err := db.NewUserQuery().SetUserName(username).SetPassword(utils.Hmac(userPasswordKey, password)).QueryOne()
	if err != nil {
		if err == db.ErrUserNotExist {
			return "", model.ErrUserNotExist
		}

		return "", err
	}

	token, err := newJWT(strconv.FormatUint(user.ID, 10), userAccessTokenExpSec)
	if err != nil {
		return "", err
	}

	userData := map[string]interface{}{
		db.UserColumnToken: token,
	}

	err = db.NewUserQuery().SetID(user.ID).Updates(userData)
	if err != nil {
		return "", err
	}

	return token, nil
}
