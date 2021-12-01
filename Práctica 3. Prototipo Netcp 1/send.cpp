#include "socket.hpp"

int main(int argc, char *argv[]){

  if(argc != 2){
    std::cout << "Error apertura." << std::endl;
    std::cout << "\nModo de empleo: './send [prueba.txt]'" << std::endl;
    return -1;
  }

  // Les asignamos una ip a cada una llamando a la funcion creada "make_ip_adress"
  sockaddr_in local_address = make_ip_address("127.0.0.1", 8081); // 1
  sockaddr_in dest_address = make_ip_address("127.0.0.1", 8080); // 0

  Socket socket(local_address);
  Message message;

  int fe = open("prueba.txt", O_RDONLY);
  if(fe < 0) {
    return 1;
  }

  int n = -1;
  char* buffer;
  while(n != 0) {
    n = read(fe, buffer ,1023); // leemos
    std::string str(buffer); 
    str.copy(message.text.data(), message.text.size() - 1, 0); // copiamos
    socket.send_to(message, dest_address);                    // enviamos
  }

  close(fe);

}
