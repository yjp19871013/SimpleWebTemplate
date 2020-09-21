package service

import (
	"{{ .ProjectConfig.PackageName }}/db"
)

// Init 初始化service
func Init() {
	err := db.Open()
	if err != nil {
		panic(err)
	}

	err = initPermissions()
	if err != nil {
		panic(err)
	}

	err = initAdmin()
	if err != nil {
		panic(err)
	}
}
