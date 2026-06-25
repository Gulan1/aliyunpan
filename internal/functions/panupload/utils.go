// Copyright (c) 2020 tickstep.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package panupload

import (
	"crypto/sha1"
	"encoding/hex"
	"github.com/tickstep/aliyunpan/internal/config"
	"github.com/tickstep/library-go/converter"
	"github.com/tickstep/library-go/logger"
	"net/url"
	"os"
	"path"
	"strconv"
	"strings"
	"time"
)

const (
	// MaxUploadBlockSize 最大上传的文件分片大小
	MaxUploadBlockSize = 2 * converter.GB
	// MinUploadBlockSize 最小的上传的文件分片大小
	MinUploadBlockSize = 4 * converter.MB
	// MaxRapidUploadSize 秒传文件支持的最大文件大小
	MaxRapidUploadSize = 20 * converter.GB

	// UploadingFileName 上传文件上传状态的文件名
	UploadingFileName = "aliyunpan_uploading.json"
	// UploadingBackupFileName 上传文件上传状态的副本
	UploadingBackupFileName = "aliyunpan_uploading.json.bak"
)

var (
	cmdUploadVerbose = logger.New("FILE_UPLOAD", config.EnvVerbose)
)

func getBlockSize(fileSize int64) int64 {
	blockNum := fileSize / MinUploadBlockSize
	if blockNum > 999 {
		return fileSize/999 + 1
	}
	return MinUploadBlockSize
}

// IsUrlExpired 上传链接是否已过期。过期返回True
func IsUrlExpired(urlStr string) bool {
	u, err := url.Parse(urlStr)
	if err != nil {
		return true
	}
	
	expiredTimeSecStr := u.Query().Get("x-oss-expires")
	expiredTimeSec, _ := strconv.ParseInt(expiredTimeSecStr, 10, 64)
	
	// 判断是OSS V4签名（相对时间）还是旧签名（绝对时间戳）
	// OSS V4: x-oss-expires通常<86400(1天)，且有x-oss-date参数
	// 旧格式: x-oss-expires是很大的时间戳(>1000000000)
	if expiredTimeSec < 86400 {
		// OSS V4签名格式：x-oss-expires是相对秒数
		ossDateStr := u.Query().Get("x-oss-date")
		if ossDateStr != "" {
			// 解析x-oss-date时间 (格式: 20260625T150405Z)
			ossDate, err := time.Parse("20060102T150405Z", ossDateStr)
			if err != nil {
				logger.Verbosef("DEBUG: parse x-oss-date error: %s\n", err)
				return true
			}
			// 计算过期时间 = 签名时间 + 有效期秒数
			expireTime := ossDate.Add(time.Duration(expiredTimeSec) * time.Second)
			// 判断是否还有超过5分钟有效期
			if time.Until(expireTime).Seconds() <= 300 {
				return true
			}
			return false
		}
	}
	
	// 旧格式：x-oss-expires是绝对时间戳
	if (expiredTimeSec - time.Now().Unix()) <= 300 { // 小于5分钟
		// expired
		return true
	}
	return false
}

func IsVideoFile(fileName string) bool {
	if fileName == "" {
		return false
	}
	extName := strings.ToLower(path.Ext(fileName))
	if strings.Index(extName, ".") == 0 {
		extName = strings.TrimPrefix(extName, ".")
	}
	extList := config.Config.GetVideoExtensionList()
	for _, ext := range extList {
		if ext == extName {
			return true
		}
	}
	return false
}

// CalcFilePreHash 计算文件 PreHash
func CalcFilePreHash(filePath string) string {
	localFile, _ := os.OpenFile(filePath, os.O_RDONLY, 0)
	defer localFile.Close()
	bytes := make([]byte, 1024)
	localFile.ReadAt(bytes, 0)
	sha1w := sha1.New()
	sha1w.Write(bytes)
	shaBytes := sha1w.Sum(nil)
	hashCode := hex.EncodeToString(shaBytes)
	return strings.ToUpper(hashCode)
}
