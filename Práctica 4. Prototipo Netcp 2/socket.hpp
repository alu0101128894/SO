#ifndef SOCKET_HPP
#define SOCKET_HPP

#pragma once
#include <sys/types.h>
#include <sys/socket.h>
#include <array>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <iostream>
#include <unistd.h>
#include <cstring>
#include <cerrno>
#include <exception>
#include <system_error>
#include <fstream>
#include <sys/stat.h>
#include <fcntl.h>
#include <thread>
#include <functional>
#include <pthread.h>
#include <atomic>
#include <csignal>
#include <vector>
#include <set>
#include <sstream>



//Funcionalidades que no pertenecen a la clase socket

struct Message {
    std::array<char, 1024> text; //Igual que char text[1024] pero recomendado asi en C++
};

sockaddr_in make_ip_address(const std::string& ip_address, int port);

class Socket{
  public:
    Socket(sockaddr_in& address);
    ~Socket();

    void send_to(const Message& message, const sockaddr_in& address); //Funcion para enviar mensajes
    void receive_from(Message& message, sockaddr_in& address); //Funcion para recibir mensajes

  private:
    int fd_;
};

#endif