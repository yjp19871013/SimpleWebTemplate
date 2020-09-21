package model

import "errors"

var (
	ErrParam        = errors.New("没有传递必要的参数")
	ErrTokenInvalid = errors.New("无效的token")
	ErrUserNotExist = errors.New("用户不存在")
	ErrRoleNotExist = errors.New("角色不存在")
)
