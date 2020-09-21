package service

import (
	"{{ .ProjectConfig.PackageName }}/casbin"
	"{{ .ProjectConfig.PackageName }}/db"
	"{{ .ProjectConfig.PackageName }}/service/model"
	"{{ .ProjectConfig.PackageName }}/utils"
)

const (
	userPasswordKey = "fs0351su123per"
)

const (
	userAccessTokenExpSec = 3 * 3600
)

const (
	adminUserName     = "{{ .AdminUserConfig.Username }}"
    adminUserPassword = "{{ .AdminUserConfig.Password }}"
    adminUserRoleName = "{{ .AdminUserConfig.Role }}"
)

func initAdmin() error {
	exist, err := db.NewUserQuery().SetUserName(adminUserName).CheckCount(1)
	if err != nil {
		return err
	}

	if exist {
		return nil
	}

	_, err = CreateSuperAdminUser(adminUserName, adminUserPassword)
	if err != nil {
		return err
	}

	return nil
}

func CreateSuperAdminUser(username string, password string) (uint64, error) {
	if utils.IsStringEmpty(username) || utils.IsStringEmpty(password) {
		return 0, model.ErrParam
	}

	return createUser(username, password, adminUserRoleName)
}

func CreateCommonUser(username string, password string, roleName string) (uint64, error) {
	if utils.IsStringEmpty(username) || utils.IsStringEmpty(password) || utils.IsStringEmpty(roleName) {
		return 0, model.ErrParam
	}

	if roleName == adminUserRoleName {
		return 0, model.ErrRoleNotExist
	}

	return createUser(username, password, roleName)
}

func UpdateCommonUserPassword(id uint64, password string) error {
	if id == 0 || utils.IsStringEmpty(password) {
		return model.ErrParam
	}

	user, err := db.NewUserQuery().SetID(id).QueryOne()
	if err != nil {
		if err == db.ErrUserNotExist {
			return model.ErrUserNotExist
		}

		return err
	}

	if user.UserName == adminUserName {
		return model.ErrUserNotExist
	}

	userData := map[string]interface{}{
		db.UserColumnPassword: utils.Hmac(userPasswordKey, password),
	}

	return db.NewUserQuery().SetID(id).Updates(userData)
}

func DeleteCommonUser(id uint64) error {
	if id == 0 {
		return model.ErrParam
	}

	user, err := db.NewUserQuery().SetID(id).QueryOne()
	if err != nil {
		if err == db.ErrUserNotExist {
			return model.ErrUserNotExist
		}

		return err
	}

	if user.UserName == adminUserName {
		return model.ErrUserNotExist
	}

	err = casbin.DeleteRoleForUser(user.ID, user.Role)
	if err != nil {
		return err
	}

	return db.NewUserQuery().SetID(id).Delete()
}

func GetUserByToken(token string) (*model.UserInfo, error) {
	if utils.IsStringEmpty(token) {
		return nil, model.ErrParam
	}

	user, err := db.NewUserQuery().SetToken(token).QueryOne()
	if err != nil {
		if err == db.ErrUserNotExist {
			return nil, model.ErrUserNotExist
		}

		return nil, err
	}

	return model.TransferUserToUserInfo(user), nil
}

func createUser(username string, password string, roleName string) (uint64, error) {
	roleExist, err := casbin.HasRole(roleName)
	if err != nil {
		return 0, err
	}

	if !roleExist {
		return 0, model.ErrRoleNotExist
	}

	user := &db.User{
		UserName: username,
		Password: utils.Hmac(userPasswordKey, password),
		Role:     roleName,
	}

	err = user.Create()
	if err != nil {
		return 0, err
	}

	err = casbin.AddRoleForUser(user.ID, user.Role)
	if err != nil {
		return 0, err
	}

	return user.ID, err
}

func GetUsers(pageNo int, pageSize int) ([]model.UserInfo, int64, error) {
	users, err := db.NewUserQuery().NotUserName(adminUserName).Query(pageNo, pageSize)
	if err != nil && err != db.ErrUserNotExist {
		return nil, 0, err
	}

	totalCount, err := db.NewUserQuery().NotUserName(adminUserName).Count()
	if err != nil {
		return nil, 0, err
	}

	return model.TransferUserToUserInfoBatch(users), totalCount, nil
}
