Recomendaciones: 

Siempre en caso de error logear datos en el flujo para saber que datos estamos enviando y recibiendo.

`collection.UpdateOne(ctx, filter, update)` devuelve un `mongo.UpdateResult` que contiene información sobre la operación de actualización. Allí facilmente podemos ver si efectivamente se actualizó un documento o no.

Ahí podemos ver que el campo `ModifiedCount` nos indica la cantidad de documentos que se actualizaron. Si es 0, significa que no se actualizó ningún documento.

En nuestro caso, no nos devolvía error, pero tambien el UpdateResult venia todo vacio, por lo que podemos sospechar que no se estaba actualizando ningún documento segun nuestro filtro.

Veo que el filtro que estamos usando es `bson.M{"_id": id}`. El problema es que el campo `_id` es de tipo `primitive.ObjectID` y el valor que estamos pasando es de tipo `string`. Por lo que el filtro no encuentra ningún documento que coincida con el id que le estamos pasando, podemos usar primitive.ObjectIDFromHex para castear el string a un primitive.ObjectID.

https://pkg.go.dev/go.mongodb.org/mongo-driver/bson/primitive#ObjectIDFromHex
https://www.mongodb.com/docs/manual/reference/method/ObjectId/

Otras recomendaciones:

NUNCA subas contraseñas a repositorios públicos, ni siquiera en un archivo de configuración. Siempre usa variables de entorno para configurar tu aplicación, acá te dejo un link mio de como hacerlo en Go:

https://german-mendieta.notion.site/Como-cargar-variables-de-entorno-f142e142f7da43bd831fd83b637c3498?pvs=4


Moví el archivo de configuración a la carpeta config, y cree un archivo .env.example para que puedas ver como debería ser el archivo .env que deberías crear en tu computadora.