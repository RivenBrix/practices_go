package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	// "github.com/rs/cors"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var collection *mongo.Collection
var client *mongo.Client

// c := cors.AllowAll()

// handler := c.Handler(router)

// log.Fatal(http.ListenAndServe(":8080", handler))

type Person struct {
	//_id      string `json:"_id"`
	ID       primitive.ObjectID `json:"_id,omitempty" bson:"_id,omitempty"`
	Nombre   string             `json:"Nombre"`
	Email    string             `json:"Email"`
	Fecha    string             `json:"Fecha"`
	Password string             `json:"Password"`
	Rol      string             `json:"Rol"`
}

func InsertData(w http.ResponseWriter, r *http.Request) {
	var person Person

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Printf("Error al leer el cuerpo de la solicitud: %v", err)
		http.Error(w, "Error interno", http.StatusInternalServerError)
		return
	}
	log.Printf("Cuerpo de la solicitud: %s", body)

	err = json.NewDecoder(bytes.NewReader(body)).Decode(&person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		log.Printf("Error al decodificar datos de la solicitud: %v", err)
		return
	}

	// err := json.NewDecoder(r.Body).Decode(&person)

	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		log.Printf("Error al decodificar datos de la solicitud: %v", err)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	fmt.Println("Person", person)
	_, err = collection.InsertOne(ctx, person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		log.Printf("Error al insertar datos en MongoDB: %v", err)
		return
	}

	w.WriteHeader(http.StatusOK)
	log.Println("Datos insertados con éxito en MongoDB:", person)
}

func main() {
	clientOptions := options.Client().ApplyURI("mongodb+srv://cucho23:Elgotto@cluster0.v02qv6d.mongodb.net/test") // Reemplaza con tu URL de MongoDB.
	client, err := mongo.Connect(context.Background(), clientOptions)
	if err != nil {
		log.Fatal(err)
	}

	defer client.Disconnect(context.Background())

	// Configura la colección
	collection = client.Database("test").Collection("users") // Reemplaza con tu base de datos y colección.

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
	log.Fatal(http.ListenAndServe("192.168.1.42:8080", router))
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

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Printf("Error al leer el cuerpo de la solicitud: %v", err)
		http.Error(w, "Error interno", http.StatusInternalServerError)
		return
	}
	log.Printf("Cuerpo de la solicitud: %s", body)

	err = json.NewDecoder(bytes.NewReader(body)).Decode(&person)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		log.Printf("Error al decodificar datos de la solicitud: %v", err)
		return
	}

	// err := json.NewDecoder(r.Body).Decode(&person)
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

//algo asi debe ser el filtro  que me dices??
	//filter := bson.D{{"_id", bson.ObjectIdHex(params["id"])}}
	filter := bson.D{{"_id", params["id"]}}
	log.Printf("Filtro de actualización: %+v", filter)

	update := bson.D{
		{"$set", bson.D{
			{"nombre", person.Nombre},
			{"email", person.Email},
			{"fecha", person.Fecha},
		}},
	}

	_, err = collection.UpdateOne(ctx, filter, update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	log.Println("Datos actualizados con éxito en MongoDB:", person)
}
