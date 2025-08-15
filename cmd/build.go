/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"os"
	"os/exec"
	"runtime"

	"github.com/spf13/cobra"
)

var (
	supported []string = []string{
		// "axios",
		"dart",
		// "go",
		// "python",
	}
	verbose bool
)

// buildCmd represents the build command
var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "构建",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Println("Using https://dev.api.puupee.com/swagger/v1/swagger.json")

		// 获取远程声明
		resp, err := http.Get("https://dev.api.puupee.com/swagger/v1/swagger.json")
		checkError(err)
		defer resp.Body.Close()
		bts, err := io.ReadAll(resp.Body)
		checkError(err)

		// 写入本地文件
		err = os.WriteFile("swagger.json", bts, fs.ModePerm)
		checkError(err)

		// 获取版本信息
		swagger := make(map[string]interface{})
		err = json.Unmarshal(bts, &swagger)
		checkError(err)
		info := swagger["info"].(map[string]interface{})
		version := info["version"].(string)
		fmt.Printf("Building target version: %s\n", version)

		// 根据不同语言生成代码
		for _, lang := range supported {
			cmd.Printf("Building lang: %s\n", lang)
			c := exec.Command("task", lang, "VERSION="+version)
			if verbose {
				c.Stdout = os.Stdout
				c.Stderr = os.Stderr
			}
			err = c.Run()
			checkError(err)
		}
		cmd.Println("Locking into version.lock")
		// 写入版本锁
		err = os.WriteFile("version.lock", []byte(version), fs.ModePerm)
		checkError(err)

		cmd.Println("Updating generator version")
		cu := exec.Command("task", "update-self", "VERSION="+version)
		if verbose {
			cu.Stdout = os.Stdout
			cu.Stderr = os.Stderr
		}
		err = cu.Run()
		checkError(err)
		cmd.Printf("Complete! Version: %s\n", version)
	},
}

func checkError(err error) {
	if err != nil {
		fmt.Println(err.Error())
		// 打印错误堆栈
		buf := make([]byte, 1024)
		runtime.Stack(buf, true)
		fmt.Println(string(buf))
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(buildCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// buildCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// buildCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	buildCmd.Flags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
	buildCmd.MarkFlagRequired("lang")
}
