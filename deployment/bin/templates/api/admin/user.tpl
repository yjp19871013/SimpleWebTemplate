package admin

import (
	"errors"
	"github.com/gin-gonic/gin"
	"net/http"
	"{{ .ProjectConfig.PackageName }}/api/dto"
	"{{ .ProjectConfig.PackageName }}/log"
	"{{ .ProjectConfig.PackageName }}/service"
	"{{ .ProjectConfig.PackageName }}/utils"
	"strconv"
)

// CreateUser godoc
// @Summary 创建用户
// @Description 创建用户
// @Tags (admin)用户管理
// @Accept  json
// @Produce json
// @Param Authorization header string true "Authentication header"
// @Param AdminCreateUserRequest body dto.AdminCreateUserRequest true "用户信息"
// @Success 200 {object} dto.CreateUserResponse
// @Failure 400 {object} dto.CreateUserResponse
// @Failure 500 {object} dto.CreateUserResponse
// @Router /{{ .ProjectConfig.UrlPrefix }}/api/admin/user [post]
func CreateUser(c *gin.Context) {
	var err error

	defer func() {
		if err != nil {
			log.Error("CreateUser", err.Error())
		}
	}()

	formFailureResponse := func() *dto.CreateUserResponse {
        return &dto.CreateUserResponse{
            MsgResponse: dto.FormFailureMsgResponse("创建用户失败", err),
            UserInfo:    *dto.FormUserInfoWithID(nil),
        }
    }

	request := new(dto.AdminCreateUserRequest)
	err = c.ShouldBindJSON(request)
	if err != nil {
		c.JSON(http.StatusBadRequest, *formFailureResponse())
		return
	}

	userInfo, err := service.CreateCommonUser(request.Username, request.Password, request.RoleName)
	if err != nil {
		c.JSON(http.StatusOK, *formFailureResponse())
		return
	}

	c.JSON(http.StatusOK, dto.CreateUserResponse{
		MsgResponse: dto.FormSuccessMsgResponse("创建用户成功"),
		UserInfo:    *dto.FormUserInfoWithID(userInfo),
	})
}

// UpdateUser godoc
// @Summary 修改用户密码
// @Description 修改用户密码
// @Tags (admin)用户管理
// @Accept  json
// @Produce json
// @Param Authorization header string true "Authentication header"
// @Param AdminUpdateUserPasswordRequest body dto.AdminUpdateUserPasswordRequest true "修改用户密码请求"
// @Success 200 {object} dto.MsgResponse
// @Failure 400 {object} dto.MsgResponse
// @Failure 500 {object} dto.MsgResponse
// @Router /{{ .ProjectConfig.UrlPrefix }}/api/admin/user [put]
func UpdateUserPassword(c *gin.Context) {
	var err error

	defer func() {
		if err != nil {
			log.Error("UpdateUserPassword", err.Error())
		}
	}()

	request := new(dto.AdminUpdateUserPasswordRequest)
	err = c.ShouldBindJSON(request)
	if err != nil {
		dto.Response400Json(c, err)
		return
	}

	err = service.UpdateCommonUserPassword(request.ID, request.Password)
	if err != nil {
		dto.Response200FailJson(c, err)
		return
	}

	dto.Response200Json(c, "修改用户密码成功")
}

// DeleteUser godoc
// @Summary 删除用户
// @Description 删除用户
// @Tags (admin)用户管理
// @Accept  json
// @Produce json
// @Param Authorization header string true "Authentication header"
// @Param id path string true "用户ID"
// @Success 200 {object} dto.MsgResponse
// @Failure 400 {object} dto.MsgResponse
// @Failure 500 {object} dto.MsgResponse
// @Router /{{ .ProjectConfig.UrlPrefix }}/api/admin/user/{id} [delete]
func DeleteUser(c *gin.Context) {
	var err error

	defer func() {
		if err != nil {
			log.Error("DeleteUser", err.Error())
		}
	}()

	idStr := c.Param("id")
	if utils.IsStringEmpty(idStr) {
		dto.Response400Json(c, errors.New("没有传递用户ID"))
		return
	}

	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		dto.Response400Json(c, err)
		return
	}

	err = service.DeleteCommonUser(id)
	if err != nil {
		dto.Response200FailJson(c, err)
		return
	}

	dto.Response200Json(c, "删除用户成功")
}

// GetUsers godoc
// @Summary 获取用户
// @Description 获取用户
// @Tags (admin)用户管理
// @Accept  json
// @Produce json
// @Param Authorization header string true "Authentication header"
// @Param userId query string false "用户ID"
// @Param pageNo query string false "页码"
// @Param pageSize query string false "页大小"
// @Success 200 {object} dto.GetUsersResponse
// @Failure 400 {object} dto.GetUsersResponse
// @Failure 500 {object} dto.GetUsersResponse
// @Router /{{ .ProjectConfig.UrlPrefix }}/api/admin/users [get]
func GetUsers(c *gin.Context) {
	var err error

	defer func() {
		if err != nil {
			log.Error("GetUsers", err.Error())
		}
	}()

	formFailureResponse := func() *dto.GetUsersResponse {
        return &dto.GetUsersResponse{
            MsgResponse: dto.FormFailureMsgResponse("获取用户失败", err),
            TotalCount:  0,
            Infos:       dto.FormUserInfoWithIDBatch(nil),
        }
    }

	query := new(dto.AdminGetUsersQuery)
	err = c.ShouldBindQuery(query)
	if err != nil {
		c.JSON(http.StatusBadRequest, *formFailureResponse())
		return
	}

	userInfos, totalCount, err := service.GetUsers(query.UserID, query.PageNo, query.PageSize)
	if err != nil {
		c.JSON(http.StatusOK, *formFailureResponse())
		return
	}

	c.JSON(http.StatusOK, dto.GetUsersResponse{
		MsgResponse: dto.FormSuccessMsgResponse("获取用户成功"),
		TotalCount:  totalCount,
		Infos:       dto.FormUserInfoWithIDBatch(userInfos),
	})
}
