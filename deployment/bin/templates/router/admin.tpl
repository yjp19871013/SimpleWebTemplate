package router

import (
	"github.com/gin-gonic/gin"
	"{{ .ProjectConfig.PackageName }}/api/admin"
	"{{ .ProjectConfig.PackageName }}/api/middleware"
)

var (
	adminPostRouter = map[string][]gin.HandlerFunc{
		"/user": {admin.CreateUser},
	}

	adminDeleteRouter = map[string][]gin.HandlerFunc{
		"/user/:id": {admin.DeleteUser},
	}

	adminPutRouter = map[string][]gin.HandlerFunc{
		"/user": {admin.UpdateUserPassword},
	}

	adminGetRouter = map[string][]gin.HandlerFunc{
		"/roles": {admin.GetRoles},
		"/users": {admin.GetUsers},
	}
)

func initAdminRouter(r *gin.Engine) {
	groupAdmin := r.Group(urlPrefix+"/api/admin", middleware.Authentication())

	for path, f := range adminGetRouter {
		groupAdmin.GET(path, f...)
	}

	for path, f := range adminPostRouter {
		groupAdmin.POST(path, f...)
	}

	for path, f := range adminDeleteRouter {
		groupAdmin.DELETE(path, f...)
	}

	for path, f := range adminPutRouter {
		groupAdmin.PUT(path, f...)
	}
}
