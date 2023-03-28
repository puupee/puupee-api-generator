/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"io/ioutil"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/spf13/cobra"
)

var supported []string = []string{"axios", "dart", "go", "python"}

// buildCmd represents the build command
var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "构建",
	Run: func(cmd *cobra.Command, args []string) {
		// 获取 build-number
		bts, err := ioutil.ReadFile("build-number")
		cobra.CheckErr(err)
		bnStr := string(bts)
		buildNumber, err := strconv.Atoi(bnStr)
		cobra.CheckErr(err)
		buildNumber++
		swaggerBts, err := ioutil.ReadFile("swagger.json")
		cobra.CheckErr(err)
		swagger := make(map[string]interface{})
		err = json.Unmarshal(swaggerBts, &swagger)
		cobra.CheckErr(err)
		info := swagger["info"].(map[string]interface{})
		version := info["version"].(string)
		buildVersion := fmt.Sprintf("%s+%d", version, buildNumber)
		fmt.Printf("Building target version: %s\n", buildVersion)
		for _, lang := range supported {
			filename := fmt.Sprintf("config-templates/%s.json", lang)
			fileBts, err := ioutil.ReadFile(filename)
			cobra.CheckErr(err)
			content := strings.ReplaceAll(string(fileBts), "${VERSION}", buildVersion)
			err = ioutil.WriteFile(strings.ReplaceAll(filename, "config-templates", "configs"), []byte(content), fs.ModePerm)
			cobra.CheckErr(err)
		}
		c := exec.Command("task", "all")
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		err = c.Run()
		cobra.CheckErr(err)
		err = ioutil.WriteFile("build-number", []byte(fmt.Sprintf("%d", buildNumber)), fs.ModePerm)
		cobra.CheckErr(err)
	},
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
}
