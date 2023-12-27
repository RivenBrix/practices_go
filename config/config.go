package config

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var Client *mongo.Client

func GetConfig() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	//get env url
	mongoDBUrl := os.Getenv("MONGODB_URL")
	fmt.Println("MONGODB_URL", mongoDBUrl)

	// Set client options
	clientOptions := options.Client().ApplyURI(mongoDBUrl)
	Client, err = mongo.Connect(context.Background(), clientOptions)
	if err != nil {
		log.Fatal(err)
	}
}
