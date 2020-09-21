package service

import (
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"{{ .ProjectConfig.PackageName }}/casbin"
	"{{ .ProjectConfig.PackageName }}/config"
)

type roleConfig struct {
	Roles []role `yaml:"roles"`
}

type role struct {
	Name        string       `yaml:"name"`
	Permissions []permission `yaml:"permissions"`
}

type permission struct {
	Resource string `yaml:"resource"`
	Action   string `yaml:"action"`
}

func initPermissions() error {
	conf := new(roleConfig)
	confPath := config.Get{{ .ProjectConfig.ProjectName }}Config().RoleConfigFilePath
	data, err := ioutil.ReadFile(confPath)
	if err != nil {
		panic(err)
	}

	err = yaml.Unmarshal(data, conf)
	if err != nil {
		panic(err)
	}

	for _, role := range conf.Roles {
		roleName := role.Name
		for _, permission := range role.Permissions {
			exist, err := casbin.HasPermission(roleName, permission.Resource, permission.Action)
			if err != nil {
				return err
			}

			if exist {
				continue
			}

			err = casbin.AddRolePolicy(roleName, permission.Resource, permission.Action)
			if err != nil {
				return err
			}
		}
	}

	return nil
}

func GetRoles() ([]string, error) {
	return casbin.GetRoleNames(adminUserRoleName)
}
