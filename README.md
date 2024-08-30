# Configuración Terraform de máquina de DevSecOps en Apificación AWS

Esta configuración de Terraform permite desplegar las instancia EC2 requirida por DevSecOps en AWS en la infraestructura de Apificación.

- [Características](#características)
- [Uso](#uso)
- [Variables de Entrada](#variables-de-entrada)
- [Variables de Salida](#variables-de-salida)
- [Recursos Creados](#recursos-creados)
- [Dependencias](#dependencias)
- [Pruebas](#pruebas)
- [Configuración del Pre-Commit Hook](#configuración-del-pre-commit-hook)
- [Consideraciones](#consideraciones)

## Características

- Configura el proveedor AWS y establece el backend de estado remoto de Terraform en un bucket S3. 

- Recupera los datos del estado de Terraform remoto `networking-apificaion.tfstate` que corresponde a la configuración de la infraestructura de red de Apificación para obtener la información sobre los recursos de lo grupos de seguridad y las subnets.

- Crea un role IAM con una política especificada en el archivo `policies/assume_role_policy.json` y asocia las politicas especificadas en `var.roles` para la instancia. A su vez crea el perfil de instancia IAM para esos roles.

- Permite especificar filtros y propietarios para seleccionar la AMI correcta para las instancias EC2 a través del mapa de objetos `ami_filters` y la cadena `ami_owners`. 

- Permite especificar el tamaño y tipo del volumen raíz de las instancias EC2, así como cualquier volumen EBS adicional se desee asociar a tráves de los valores del objeto `root_volume` y el mapa de objetos `ebs_volumes`.

- Despliega una instancia EC2.

- Permite asignar las etiquetas especificadas en `tags` a todos los recursos generados, incluyendo la etiqueta `Name`, `Service Name`, `Environment` y `Date/Time` por defecto, e implementa una convención de nombrado estándarizado para los recursos creados generada según el tipo de recurso.

## Uso

Para la ejecución de la configuración deben seguirse los siguientes puntos:

- Se debe de seleccionar el workspace que se utilizará para la creación de los recursos (`dev`, `qa` o `prod`) a través de `terraform workspace <nombre del workspace>`. En caso de que el workspace no éste creado, se crea apartir de `terraform workspace new <nombre del workspace>`.

- Debe de crearse un archivo `.tfvars` donde se definan los valores de las variables utilizadas por la configuración. 

- Se debe de especificar la configuración del backend dentro del archivo `backend.tf`, esta configuración debe de coincidir con un bucket de S3 existente al que la cuenta de AWS que se defina para la configuración tenga permisos de acceder.

  ```hcl
  # Se especifica el backend para el estado de Terraform, en este caso un bucket S3.
  terraform {
    backend "s3" {
      bucket               = "<nombre del bucket>"
      key                  = "<ruta del archivo .tfstate>"
      workspace_key_prefix = "<prefijo del workspace>"
      region               = "<región en la que se encuentra el bucket>"
      endpoints = {
        s3 = "https://s3.<región>.amazonaws.com"
      }
    }
  }
  ```

- Se debe de especificar la configuración del backend dentro del archivo `backend.tf`, para acceder al bucket S3 en donde se encuentra el estado remoto de Terraform `networking-apificacion.tfstate` que corresponde a la configuración de la infraestructura de red. La configuración debe de coincidir con un bucket de S3 existente al que la cuenta de AWS que se defina para la configuración tenga permisos de acceder. También se debe de asegurar que el workspace en donde se esta generando la configuración, sea la correspondiente.

  ```hcl
  # Obtiene el estado de Terraform 'networking-apificacion.tfstate' de la infraestructura de red existente desde un bucket S3.
  data "terraform_remote_state" "networking_state" {
    backend   = "s3"
    workspace = terraform.workspace
    config = {
      bucket               = "<nombre del bucket>"
      key                  = "<ruta del archivo networking-devsecops.tfstate>"
      workspace_key_prefix = "<prefijo del workspace>"
      region               = "<región en la que se encuentra el bucket>"
      endpoints = {
        s3 = "https://s3.<región>.amazonaws.com"
      }
    }
  }
  ```

- De igual forma, debe de colocarse la ruta adecuada del módulo `Unity-VM-module` o en su defecto modificar la rutas del mismo en el archivo `main.tf`.

- Deben de definirse las credeciales de la cuenta de AWS para poder desplegar los recursos, acceder al backend en donde se almacenará el archivo del estado de terraform `.tfstate` y  aceder al bucket donde se encuentra el archivo `networking-apificaión.tfstate`.

Una vez se completa con lo anterior, se ejecuta el comando para inicializar el provedor y la configuración del backend.

```bash
$ terraform init
```

Posteriormente, se ejecuta el plan y se verifica el mismo, para asegurar la creación de la configuración deseada para cada uno de los recursos.

```bash
$ terraform plan -var-file="<archivo de los valores de la configuración>" -var "profile=<profile>" -var "ami_owners=xxxxxx"
```

Si se esta de acuerdo con el plan, se aplica y acepta para la creación de los recursos.

```bash
$ terraform apply -var-file="<archivo de los valores de la configuración>" -var "profile=<profile>" -var "ami_owners=xxxxxx"
```

## Variables de entrada

La configuración tiene las siguientes variables de entrada:

- `ami_filters` - Mapa de filtros para seleccionar la AMI que se utilizará para desplegar la instancia. Cada filtro está representado por un objeto con los siguientes atributos:

    - `name` - Nombre del filtro que se aplicará sobre la selección de la AMI.
    
    - `values`- Valores específicos que el filtro debe cumplir para la selección de la AMI.

- `ami_owners` - Identificador de cuenta que se utiliza para definir a quién le pertenece la AMI que se especifica a través de `ami_filters`.

- `associate_public_ip_address` - Variable utilizada para indicar si debe asociarse o no una dirección IP pública a la instancia.

- `cpu_credits` - Opción de creditos para el uso del CPU (`standard` o `unlimited`). Aplica solo a `instance_type` de la serie T (`t2`, `t3`, `t3a` y `t4g`). 

- `ebs_volumes` - Mapa de las unidades EBS que se asociaran a la instancia. Cada EBS está representado por un objeto con los siguientes atributos:

    - `device_name` -  Nombre del volumen en la instancia.

    - `volumen_type` - Tamaño del volumen en GB.

    - `volumen_type` -  Tipo de volumen, por ejemplo, gp2, io1, st1, sc1, etc.

    - `stateful` - Valor booleano que indica si el EBS debe mantener la información, incluso si la instancia cambia.

- `environment` - Ambiente en el que se e desplegará la instancia, por ejemplo, prod, dev, qa.

- `instance_type` - Tipo de instancia que serán desplegada.

- `monitoring` - Habilita el monitoreo detallado para la instancia.

- `private_ip`- Dirección IP privada que se le asignará a la instancia.

- `partial_name` - Nombre parcial para formar el nombre de la instancia.

- `root_volume` - Estructuta que contendrá el tamaño y el tipo de la unidad de almacenamiento raíz de la instancia. Está representada por los siguientes atributos:

    - `size` - Tamaño del volumen raíz.

    - `type` - Tipo de volumen raíz, por ejemplo, gp2, io1, st1, sc1, etc.

- `roles` - Objeto que contendrá la definición del para el esclavo de Jenkins (`jenkins-slave`).  El rol contiene un mapa de objetos que representán las políticas que se asignarán a los roles. Cada elemento del mapa cuentan con los siguientes atributos:

  - `description` - Descripción de la política.

  - `file` - Nombre del archivo en formato `.json` con la definición de la politica. Dicho archivo debe estar contenido en la carpeta `policies`. 

- `tags` - Mapa de etiquetas para asignar a los recursos creados.

## Variables de salida

La configuración tiene las siguientes variables de salida:

- `vm_data` - Estructura que contine la información de la instancia EC2 creada. Está representada por un objeto con los siguientes atributos:

    - `instance_id` - Identificador de la instancia generada.

    - `private_ip` - IP privada de la instancia generada.


## Recursos creados

Esta configuración crea los siguientes recursos:

- Un rol IAM con la políticas especificadas en la carpeta `policies`. 

- Un perfil de instancia IAM para el maestro de Jenkins.

- Una intancia EC2. Las instancia se crea con la AMI especificada por los filtros en `ami_filters` en la región especificada por la variable `region` y con los volúmenes especificados en `root_volume` y `ebs_volumes`.

## Dependencias

- Requiere del proveedor aws, la versión recomendada es la ~> 5.0.

- Es necesario tener instalado AWS CLI v2 para gestionar y configurar adecuadamente los recursos de AWS.

- Requiere de la existencia de la infraestructura de red (VPC, subredes y grupos de seguridad) sobre la cual se desplegarán las instancias EC2. El estado de esta infraestructura de red debe estar almacenado en un bucket de S3 especificado en la configuración como `networking-apificacion.tfstate`.

- Requiere que exista un bucket S3 como se especifica en la configuración en  donde se almacenará el estado de Terraform. 

-  Requiere de un archivo de política de IAM (por defecto, `policies/assume_role_policy.json` como se especifica en la configuración) que define los permisos para el rol de IAM que será asumido por las instancias EC2.

- Requiere que los archivos de las politicas definidos en `var.roles` se encuentren en la carpeta de `policies`.

- Esta configuración depende del módulo `Unity-VM-module` que es utilizado para la creación de la instancia EC2.

## Pruebas

Este módulo incorpora pruebas unitarias desarrolladas con `tftest` y `pytest`, las cuales son liberias de `python`. Las pruebas se encuentran en el directorio `test`. Para su ejecución, deben seguirse los siguientes pasos:

1. Hay que asegurarse de que `python` esté instalado en la máquina donde se llevarán a cabo las pruebas, además de instalar ambas liberias.
    ```python
      # tftest
      pip install tftest

      # pytest
      pip install pytest
    ```
2. Se debe de navegar hasta el directorio `test` dentro del repositorio.
    ```bash
    cd test
3. Se debe de ejecutar el siguiente comando:
    ```bash
    pytest
    ```

    #### Nota
    Deben configurarse las credenciales de AWS correspondientes como variables de entorno, ya que la prueba implica la creación de infraestructura real en una cuenta de AWS, lo cual podría incurrir en cargos.
    
En caso de requerir cambios en los valores de la prueba, deben modificarse los siguientes archivos:

- `test/apificacion_test.py` - Este archivo debe ser modificado si se necesitan cambios en las validaciones realizadas sobre la configuración.

- `test/unit/apificacion_test.tf` - Este archivo debe ser modificado si es necesario hacer cambios en la creación de los recursos adicionales requiridos para la prueba.

- `test/unit/apificacion_test_outputs.tf` - Si es necesario hacer cambios en las variables de salida que se toman en cuenta para la prueba, se debe ajustar este archivo. Al agregar o eliminar variables, es imprescindible realizar las modificaciones correspondientes en el archivo `test/apificacion_test.py`.

Para más información sobre la configuración y modificación de las pruebas, consultar [terraform-python-testing-helper](https://github.com/GoogleCloudPlatform/terraform-python-testing-helper). 


## Configuración del Pre-Commit Hook

Este proyecto emplea un pre-commit hook on el objetivo de asegurar que los archivos de Terraform sean correctamente formateados y validados antes de cada commit. Para su configuración, deben seguirse estos pasos:

1. Hay que asegurarse de que `Terraform` esté instalado en la máquina donde se utilizará el `pre-commit`, ya que el script emplea `terraform fmt` y `terraform validate` para las validaciones.

2. Se debe de copiar el archivo `pre-commit` del directorio `hooks` a `.git/hooks`:
   ```bash
   copy hooks\pre-commit .git\hooks\pre-commit
Al realizar un commit, el pre-commit hook verificará automáticamente los archivos de Terraform en espera de commit, los formateará con `terraform fmt`, y los validará con `terraform validate`. Si alguna de estas verificaciones falla, se detendrá el commit, permitiendo corregir los errores antes de continuar.

Cuando realice un commit, el pre-commit hook verificará automáticamente los archivos de Terraform en espera de commit, los formateará con `terraform fmt`, y los validará con `terraform validate`. Si alguna de estas verificaciones falla, el commit se detendrá, permitiéndole corregir los errores antes de continuar.

## Consideraciones

módulo.

- El profile de AWS configurado  debe tener el permiso `ec2:StopInstances` para poder apagar las máquinas virtuales. Esto asegura que no se generen problemas en la configuración cuando sea necesario reemplazar las instancias.

- El valor de la variable `partial_name` que se defina para generar la instancia EC2 debe coincidir con el valor de la misma variable que se uso para generar los recursos de red, esto para que la configuración pueda asociar de forma correcta la infraestrutura de red correspondiente a las instancias EC2.

- Los filtros definidos en la configuración para la AMI, recuperan la imagen más reciente que se haya creado con la configuración de Packer definida especificamente para las instancias de Jenkins. En caso de actualizar la imagen, solo es necesario volver a ejecutar esta configuración.

- Es importante que antes de eliminar recursos creados con esta configuración, se verifique que no haya dependencias o aplicaciones en ejecución que los estén utilizando.

- Para garantizar la seguridad, es recomendable revisar y limitar los permisos otorgados en el archivo de política `policies/assume_role_policy.json`. Otorgar permisos excesivos puede representar un riesgo de seguridad si las instancias EC2 son comprometidas.

- Habilitar el monitoreo detallado en la instancia tiene un costo adicional. Por defecto, AWS CloudWatch proporciona métricas en intervalos de 5 minutos de forma gratuita.

- Las instancias en modo `unlimited` pueden incurrir en costos adicionales si consumen más créditos de CPU de los que acumulan. Es vital controlar el uso de créditos. Sin embargo, si una instancia agota sus créditos de CPU y no está en modo `unlimited`, su rendimiento se reducirá al nivel de línea de base, lo que podría impactar en las aplicaciones que se ejecutan en la instancia.

- Por la definición de la arquitectura, hasta el momento solo se puede acceder mediante Session Manager a las instancias que contienen Jenkins instalado, se espera que un futuro se clarifique este punto.