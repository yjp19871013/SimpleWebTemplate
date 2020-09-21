package db

import "errors"

const (
	dbErrHasExist = "Error 1062"
)

var (
        ErrParam        = errors.New("没有传递必要的参数")
        ErrUserHasExist = errors.New("用户已存在")
        ErrUserNotExist = errors.New("用户不存在")
)
