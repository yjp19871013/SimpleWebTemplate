package casbin

import (
	"fmt"
	"github.com/casbin/casbin/v2"
	gormAdapter "github.com/casbin/gorm-adapter/v2"
	_ "github.com/go-sql-driver/mysql"
	"{{ .ProjectConfig.PackageName }}/config"
	"strconv"
	"sync"
)

var enforcer *casbin.Enforcer
var enforcerMutex sync.Mutex

func init() {
	template := "%s:%s@tcp(%s)/%s"
	mysqlConfig := config.Get{{ .ProjectConfig.ProjectName }}Config().DatabaseConfig
	connStr := fmt.Sprintf(template, mysqlConfig.Username, mysqlConfig.Password, mysqlConfig.Address, mysqlConfig.Schema)
	a, err := gormAdapter.NewAdapter("mysql", connStr, true)
	if err != nil {
		panic(err)
	}

	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	enforcer, err = casbin.NewEnforcer(config.Get{{ .ProjectConfig.ProjectName }}Config().CasbinConfig.ConfigFilePath, a)
	if err != nil {
		panic(err)
	}
}

func AddRolePolicy(roleName string, resource string, action string) error {
	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	err := enforcer.LoadPolicy()
	if err != nil {
		return err
	}

	_, err = enforcer.AddPolicy(roleName, resource, action)
	if err != nil {
		return err
	}

	return nil
}

func AddRoleForUser(userID uint64, roleName string) error {
	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	err := enforcer.LoadPolicy()
	if err != nil {
		return err
	}

	_, err = enforcer.AddRoleForUser(strconv.FormatUint(userID, 10), roleName)
	if err != nil {
		return err
	}

	return nil
}

func HasPermission(roleName string, resource string, action string) (bool, error) {
	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	err := enforcer.LoadPolicy()
	if err != nil {
		return false, err
	}

	return enforcer.HasPolicy(roleName, resource, action), nil
}

func HasRole(roleName string) (bool, error) {
	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	err := enforcer.LoadPolicy()
	if err != nil {
		return false, err
	}

	policies := enforcer.GetFilteredPolicy(0, roleName)
	if len(policies) == 0 {
		return false, nil
	}

	return true, nil
}

func GetRoleNames(superRoleName string) ([]string, error) {
	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	err := enforcer.LoadPolicy()
	if err != nil {
		return nil, err
	}

	roleNames := make([]string, 0)
	roleNameMap := make(map[string]bool)
	policies := enforcer.GetFilteredPolicy(0, "")
	for _, p := range policies {
		roleName := p[0]
		exist := roleNameMap[roleName]
		if exist || superRoleName == roleName {
			continue
		}

		roleNames = append(roleNames, roleName)
		roleNameMap[roleName] = true
	}

	return roleNames, nil
}

func DeleteRoleForUser(userID uint64, roleName string) error {
	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	err := enforcer.LoadPolicy()
	if err != nil {
		return err
	}

	_, err = enforcer.DeleteRoleForUser(strconv.FormatUint(userID, 10), roleName)
	if err != nil {
		return err
	}

	return nil
}

func Enforce(rvals ...interface{}) (bool, error) {
	enforcerMutex.Lock()
	defer enforcerMutex.Unlock()

	err := enforcer.LoadPolicy()
	if err != nil {
		return false, err
	}

	return enforcer.Enforce(rvals...)
}
