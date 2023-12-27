package main

import (
	"app/config"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

var collection *mongo.Collection

type Person struct {
	_id      string `json:"_id"`
	Nombre   string `json:"Nombre"`
	Email    string `json:"Email"`
	Fecha    string `json:"Fecha"`
	Password string `json:"Password"`
	Rol      string `json:"Rol"`
}

func main() {

	config.GetConfig()
	defer config.Client.Disconnect(context.Background())

	// Configura la colección
	collection = config.Client.Database("test").Collection("users") // Reemplaza con tu base de datos y colección.

	// Crear el enrutador HTTP utilizando mux
	router := mux.NewRouter()

	router.HandleFunc("/api/insert", InsertData).Methods("POST")

	router.HandleFunc("/users", GetUsers).Methods("GET")
	//metodo para el login
	router.HandleFunc("/api/login", GetUserByEmailAndPassword).Methods("POST")
	//metodo para actualizar datos de los usuarios
	router.HandleFunc("/users/{id}", UpdateUser).Methods("PUT")

	log.Println("Servidor iniciado en http://192.168.1.42:8080")

	// ":8080"
	log.Fatal(http.ListenAndServe("localhost:8080", router))
}

func InsertData(w http.ResponseWriter, r *http.Request) {
	var person Person
	err := json.NewDecoder(r.Body).Decode(&person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		log.Printf("Error al decodificar datos de la solicitud: %v", err)
		return
	}

	_, err = collection.InsertOne(context.Background(), person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		log.Printf("Error al insertar datos en MongoDB: %v", err)
		return
	}

	w.WriteHeader(http.StatusOK)
	log.Println("Datos insertados con éxito en MongoDB:", person)
}

func GetUsers(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	filter := bson.D{{}} // consulta sin filtros, devuelve todos los documentos

	cur, err := collection.Find(ctx, filter)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cur.Close(ctx)

	var persons []Person

	for cur.Next(ctx) {
		var person Person
		err := cur.Decode(&person)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		persons = append(persons, person)
	}

	jsonData, err := json.Marshal(persons)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonData)
}

// PARA BUSCAR USUARIO LOGIN
func GetUserByEmailAndPassword(w http.ResponseWriter, r *http.Request) {
	var person Person
	err := json.NewDecoder(r.Body).Decode(&person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		log.Printf("Error al decodificar datos de la solicitud: %v", err)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	// e y p estaban en mayusculas
	filter := bson.D{{"email", person.Email}, {"password", person.Password}} // consulta con filtros para Email y Password

	err = collection.FindOne(ctx, filter).Decode(&person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	jsonData, err := json.Marshal(person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonData)
}

//METODO PARA ACTUALIZAR DATOS DE LOS USUARIOS / ADMIN

func UpdateUser(w http.ResponseWriter, r *http.Request) {
	var person Person
	err := json.NewDecoder(r.Body).Decode(&person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		log.Printf("Error al decodificar datos de la solicitud: %v", err)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	params := mux.Vars(r)
	// Convertir el parámetro "id" a un ObjectId
	objectID, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		log.Printf("Error al convertir el ID a ObjectId: %v", err)
		return
	}

	filter := bson.D{{"_id", objectID}}
	fmt.Println("Filter, ", filter)
	update := bson.D{
		{"$set", bson.D{
			{"Nombre", person.Nombre},
			{"Email", person.Email},
			{"Fecha", person.Fecha},
		}},
	}

	fmt.Println("Update, ", update)

	result, err := collection.UpdateOne(ctx, filter, update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Println("Result, ", result)

	w.WriteHeader(http.StatusOK)
	log.Println("Datos actualizados con éxito en MongoDB:", person)
}
