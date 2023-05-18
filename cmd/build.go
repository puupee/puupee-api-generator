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

	"github.com/AlecAivazis/survey/v2"
	"github.com/spf13/cobra"
)

var (
	supported []string = []string{"axios", "dart", "go", "python"}
	lang      string
)

// buildCmd represents the build command
var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "构建",
	Run: func(cmd *cobra.Command, args []string) {
		// 获取 build-number
		bts, err := ioutil.ReadFile("version")
		cobra.CheckErr(err)
		latestVersion := string(bts)
		prompt := &survey.Input{
			Message: "输入构建版本号:",
			Default: latestVersion,
		}
		var version string
		err = survey.AskOne(prompt, &version, survey.WithValidator(survey.Required))
		cobra.CheckErr(err)
		if latestVersion == version {
			cmd.Println("版本号未变化，不需要构建")
			return
		}
		swaggerBts, err := ioutil.ReadFile("swagger.json")
		cobra.CheckErr(err)
		swagger := make(map[string]interface{})
		err = json.Unmarshal(swaggerBts, &swagger)
		cobra.CheckErr(err)
		info := swagger["info"].(map[string]interface{})
		info["version"] = version
		fmt.Printf("Building target version: %s\n", version)
		c := exec.Command("task", lang, "VERSION="+version)
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		err = c.Run()
		cobra.CheckErr(err)
		err = ioutil.WriteFile("version", []byte(version), fs.ModePerm)
		cobra.CheckErr(err)
		cu := exec.Command("task", "update-self", "VERSION="+version)
		cu.Stdout = os.Stdout
		cu.Stderr = os.Stderr
		err = cu.Run()
		cobra.CheckErr(err)
		cmd.Printf("构建完成! 语言: %s 版本: %s\n", lang, version)
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
	buildCmd.Flags().StringVarP(&lang, "lang", "l", "all", "目标语言")
	buildCmd.MarkFlagRequired("lang")
	buildCmd.Flags().SetAnnotation("lang", "survey", supported)
}
