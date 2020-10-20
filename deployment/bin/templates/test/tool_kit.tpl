package test

import (
	"bytes"
	"{{ .ProjectConfig.PackageName }}/api/dto"
	"{{ .ProjectConfig.PackageName }}/router"
	"{{ .ProjectConfig.PackageName }}/service"
	"{{ .ProjectConfig.PackageName }}/utils"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strconv"
	"strings"
	"testing"
)

type ToolKit struct {
	t            *testing.T
	body         io.Reader
	header       map[string]string
	queryParams  map[string]string
	jsonResponse interface{}
	token        string
	userInfo     *dto.UserInfoWithID

	responseRecorder *httptest.ResponseRecorder
}

func NewToolKit(t *testing.T) *ToolKit {
	service.Init()

	return &ToolKit{
		t:           t,
		header:      make(map[string]string),
		queryParams: make(map[string]string),
	}
}

func (toolKit *ToolKit) SetHeader(key string, value string) *ToolKit {
	toolKit.header[key] = value
	return toolKit
}

func (toolKit *ToolKit) SetQueryParams(key string, value string) *ToolKit {
	toolKit.queryParams[key] = value
	return toolKit
}

func (toolKit *ToolKit) SetJsonBody(body interface{}) *ToolKit {
	jsonBody, err := json.Marshal(body)
	if err != nil {
		toolKit.t.Fatal("转换JSON失败")
	}

	toolKit.body = bytes.NewBuffer(jsonBody)

	return toolKit
}

func (toolKit *ToolKit) SetJsonResponse(response interface{}) *ToolKit {
	responseValue := reflect.ValueOf(response)
	if responseValue.Kind() != reflect.Ptr {
		toolKit.t.Fatal("JsonResponse应该传递指针类型")
	}

	toolKit.jsonResponse = response

	return toolKit
}

func (toolKit *ToolKit) SetToken(token string) *ToolKit {
	toolKit.token = token
	return toolKit
}

func (toolKit *ToolKit) Request(url string, method string) *ToolKit {
	r := gin.Default()
	router.InitRouter(r)

	if len(toolKit.queryParams) != 0 {
		url = url + "?"
		for key, value := range toolKit.queryParams {
			url = url + key + "=" + value + "&"
		}

		url = url[:len(url)-1]
	}

	request, err := http.NewRequest(method, url, toolKit.body)
	if err != nil {
		toolKit.t.Fatal("创建请求失败", err)
	}

	if len(toolKit.header) != 0 {
		for key, value := range toolKit.header {
			request.Header.Add(key, value)
		}
	}

	if !utils.IsStringEmpty(toolKit.token) {
		request.Header.Add("Authorization", toolKit.token)
	}

	toolKit.responseRecorder = httptest.NewRecorder()
	r.ServeHTTP(toolKit.responseRecorder, request)

	if toolKit.jsonResponse != nil {
		responseBody, err := ioutil.ReadAll(toolKit.responseRecorder.Body)
		if err != nil {
			toolKit.t.Fatal("读取响应Body失败")
		}

		err = json.Unmarshal(responseBody, toolKit.jsonResponse)
		if err != nil {
			toolKit.t.Fatal("转换Response失败")
		}
	}

	return toolKit
}

func (toolKit *ToolKit) GetAccessToken(username string, password string, retToken *string) *ToolKit {
	getAccessTokenRequest := &dto.GetAccessTokenRequest{
		Username: username,
		Password: password,
	}

	getAccessTokenResponse := new(dto.GetAccessTokenResponse)

	NewToolKit(toolKit.t).SetHeader("Content-Type", "application/json").
		SetJsonBody(getAccessTokenRequest).
		SetJsonResponse(getAccessTokenResponse).
		Request("/{{ .ProjectConfig.UrlPrefix }}/api/getAccessToken", http.MethodPost).
		AssertStatusCode(http.StatusOK).
		AssertEqual(true, getAccessTokenResponse.Success, getAccessTokenResponse.Msg).
		AssertNotEmpty(getAccessTokenResponse.AccessToken)

	toolKit.token = getAccessTokenResponse.AccessToken

	if retToken != nil {
		*retToken = getAccessTokenResponse.AccessToken
	}

	return toolKit
}

func (toolKit *ToolKit) CreateUser(password string, role string, userInfo *dto.UserInfoWithID) *ToolKit {
	uuid, err := utils.GetUUID()
	if err != nil {
		toolKit.t.Fatal("生成uuid失败")
	}

	userName := "测试用户" + strings.Split(uuid, "-")[0]

	createUserRequest := &dto.AdminCreateUserRequest{
		Password: password,
		UserInfo: dto.UserInfo{
			Username: userName,
			RoleName: role,
		},
	}

	createUserResponse := new(dto.CreateUserResponse)
	NewToolKit(toolKit.t).SetToken(toolKit.token).
		SetHeader("Content-Type", "application/json").
		SetJsonBody(createUserRequest).
		SetJsonResponse(createUserResponse).
		Request("/{{ .ProjectConfig.UrlPrefix }}/api/admin/user", http.MethodPost).
		AssertStatusCode(http.StatusOK).
		AssertEqual(true, createUserResponse.Success, createUserResponse.Msg).
		AssertNotEqual(0, createUserResponse.UserInfo.ID).
		AssertEqual(userName, createUserResponse.UserInfo.Username).
		AssertEqual(role, createUserResponse.UserInfo.RoleName)

	getUsersResponse := new(dto.GetUsersResponse)
	NewToolKit(toolKit.t).SetToken(toolKit.token).
		SetHeader("Content-Type", "application/json").
		SetQueryParams("userId", strconv.FormatUint(createUserResponse.UserInfo.ID, 10)).
		SetQueryParams("pageNo", "1").
		SetQueryParams("pageSize", "1").
		SetJsonResponse(getUsersResponse).
		Request("/{{ .ProjectConfig.UrlPrefix }}/api/admin/users", http.MethodGet).
		AssertStatusCode(http.StatusOK).
		AssertEqual(true, getUsersResponse.Success, getUsersResponse.Msg).
		AssertEqual(int64(1), getUsersResponse.TotalCount).
		AssertEqual(createUserResponse.UserInfo.ID, getUsersResponse.Infos[0].ID).
		AssertEqual(createUserResponse.UserInfo.Username, getUsersResponse.Infos[0].Username).
		AssertEqual(createUserResponse.UserInfo.RoleName, getUsersResponse.Infos[0].RoleName)

	toolKit.userInfo = &createUserResponse.UserInfo

	if userInfo != nil {
		createUserResponseUserInfo := createUserResponse.UserInfo
		userInfo.ID = createUserResponseUserInfo.ID
		userInfo.Username = createUserResponseUserInfo.Username
		userInfo.RoleName = createUserResponseUserInfo.RoleName
	}

	return toolKit
}

func (toolKit *ToolKit) DeleteUser() *ToolKit {
	deleteUserResponse := new(dto.MsgResponse)
	NewToolKit(toolKit.t).SetToken(toolKit.token).
		SetHeader("Content-Type", "application/json").
		SetJsonResponse(deleteUserResponse).
		Request("/{{ .ProjectConfig.UrlPrefix }}/api/admin/user/"+strconv.FormatUint(toolKit.userInfo.ID, 10), http.MethodDelete).
		AssertStatusCode(http.StatusOK).
		AssertEqual(true, deleteUserResponse.Success, deleteUserResponse.Msg)

	toolKit.userInfo = nil

	return toolKit
}

func (toolKit *ToolKit) AssertStatusCode(code int) *ToolKit {
	assert.Equal(toolKit.t, code, toolKit.responseRecorder.Code)
	return toolKit
}

func (toolKit *ToolKit) AssertBodyEqual(body string) *ToolKit {
	assert.Equal(toolKit.t, body, toolKit.responseRecorder.Body.String())
	return toolKit
}

func (toolKit *ToolKit) AssertEqual(expected interface{}, actual interface{}, msgAndArgs ...interface{}) *ToolKit {
	assert.Equal(toolKit.t, expected, actual, msgAndArgs)
	return toolKit
}

func (toolKit *ToolKit) AssertNotEqual(expected interface{}, actual interface{}, msgAndArgs ...interface{}) *ToolKit {
	assert.NotEqual(toolKit.t, expected, actual, msgAndArgs)
	return toolKit
}

func (toolKit *ToolKit) AssertNotEmpty(object interface{}, msgAndArgs ...interface{}) *ToolKit {
	assert.NotEmpty(toolKit.t, object, msgAndArgs)
	return toolKit
}

func (toolKit *ToolKit) AssertGreaterOrEqual(e1 interface{}, e2 interface{}, msgAndArgs ...interface{}) *ToolKit {
	assert.GreaterOrEqual(toolKit.t, e1, e2, msgAndArgs)
	return toolKit
}
