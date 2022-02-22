/*
Copyright © 2022 NAME HERE <EMAIL ADDRESS>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"

	homedir "github.com/mitchellh/go-homedir"
	"github.com/spf13/viper"
)

// currentDir, err := os.Getwd()
// 	if err != nil {
// 		panic(err)
// 	}
// 	fmt.Println(currentDir)
// 	if err := replace("../doggyapi/lib/model/volo_abp_asp_net_core_mvc_application_configurations_object_extending_extension_enum_field_dto.dart", `value: json[r'value'] == null ? null : Map<String, dynamic>.fromJson(json[r'value'])`, `value: json[r'value']`); err != nil {
// 		panic(err)
// 	}
// 	if err := replace("../doggyapi/lib/model/volo_abp_asp_net_core_mvc_application_configurations_object_extending_extension_property_dto.dart", `defaultValue: json[r'defaultValue'] == null ? null : Map<String, dynamic>.fromJson(json[r'defaultValue'])`, `defaultValue: json[r'defaultValue']`); err != nil {
// 		panic(err)
// 	}
// 	if err := replace("../doggyapi/lib/model/volo_abp_http_modeling_method_parameter_api_description_model.dart", `defaultValue: json[r'defaultValue'] == null ? null : Map<String, dynamic>.fromJson(json[r'defaultValue'])`, `defaultValue: json[r'defaultValue']`); err != nil {
// 		panic(err)
// 	}
// 	if err := replace("../doggyapi/lib/model/volo_abp_http_modeling_parameter_api_description_model.dart", `defaultValue: json[r'defaultValue'] == null ? null : Map<String, dynamic>.fromJson(json[r'defaultValue'])`, `defaultValue: json[r'defaultValue']`); err != nil {
// 		panic(err)
// 	}

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "fcr",
	Short: "替换文件中的文字",
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) != 3 {
			panic("参数错误")
		}
		if err := replace(args[0], args[1], args[2]); err != nil {
			panic(err)
		}
	},
}

func replace(filename, old, new string) error {
	currentDir, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	r, err := ioutil.ReadFile(filepath.Join(currentDir, filename))
	if err != nil {
		return err
	}
	content := string(r)
	content = strings.ReplaceAll(content, old, new)
	return ioutil.WriteFile(filename, []byte(content), 0644)
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	cobra.CheckErr(rootCmd.Execute())
}

func init() {
	cobra.OnInitialize(initConfig)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.fixflutterapi.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := homedir.Dir()
		cobra.CheckErr(err)

		// Search config in home directory with name ".fixflutterapi" (without extension).
		viper.AddConfigPath(home)
		viper.SetConfigName(".fixflutterapi")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
	}
}
