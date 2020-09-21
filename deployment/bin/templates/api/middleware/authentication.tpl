package middleware

import (
	"errors"
	"github.com/dgrijalva/jwt-go/request"
	"github.com/gin-gonic/gin"
	"net/http"
	"{{ .ProjectConfig.PackageName }}/api/dto"
	"{{ .ProjectConfig.PackageName }}/service"
)

func Authentication() gin.HandlerFunc {
	return func(c *gin.Context) {
		token, err := request.AuthorizationHeaderExtractor.ExtractToken(c.Request)
		if err != nil {
			c.JSON(http.StatusUnauthorized, dto.FormFailureMsgResponse("提取Token", err))
			c.Abort()
			return
		}

		userInfo, err := service.GetUserByToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, dto.FormFailureMsgResponse("用户校验", err))
			c.Abort()
			return
		}

		pass, err := service.Authentication(userInfo.ID, c.Request.RequestURI, c.Request.Method, token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, dto.FormFailureMsgResponse("用户鉴权", err))
			c.Abort()
			return
		}

		if !pass {
			c.JSON(http.StatusUnauthorized, dto.FormFailureMsgResponse("Token校验", errors.New("非法token")))
			c.Abort()
			return
		}

		err = ReloadBodyData(c)
		if err != nil {
			c.JSON(http.StatusBadRequest, dto.FormFailureMsgResponse("加载body数据失败", err))
			c.Abort()
			return
		}

		c.Set(contextUserInfoKey, userInfo)
		c.Next()
	}
}
