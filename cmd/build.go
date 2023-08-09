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

	"github.com/spf13/cobra"
)

var (
	supported []string = []string{
		"axios",
		"dart",
		"go",
		"python",
	}
	verbose bool
)

// buildCmd represents the build command
var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "构建",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Println("Using https://dev.api.puupee.com/swagger/v1/swagger.json")
		resp, err := http.Get("https://dev.api.puupee.com/swagger/v1/swagger.json")
		cobra.CheckErr(err)
		defer resp.Body.Close()
		bts, err := io.ReadAll(resp.Body)
		cobra.CheckErr(err)
		swagger := make(map[string]interface{})
		err = json.Unmarshal(bts, &swagger)
		cobra.CheckErr(err)
		info := swagger["info"].(map[string]interface{})
		version := info["version"].(string)
		fmt.Printf("Building target version: %s\n", version)
		for _, lang := range supported {
			c := exec.Command("task", lang, "VERSION="+version)
			if verbose {
				c.Stdout = os.Stdout
				c.Stderr = os.Stderr
			}
			err = c.Run()
			cobra.CheckErr(err)
			cmd.Printf("Built! Lang: %s Version: %s\n", lang, version)
		}
		err = os.WriteFile("version.lock", []byte(version), fs.ModePerm)
		cobra.CheckErr(err)
		cu := exec.Command("task", "update-self", "VERSION="+version)
		if verbose {
			cu.Stdout = os.Stdout
			cu.Stderr = os.Stderr
		}
		err = cu.Run()
		cobra.CheckErr(err)
		cmd.Printf("Built ! Version: %s\n", version)
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
	buildCmd.Flags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
	buildCmd.MarkFlagRequired("lang")
}
