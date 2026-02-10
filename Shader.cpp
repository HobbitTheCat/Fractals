#include <GL/glew.h>
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <GLFW/glfw3.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>

class Shader {
private:
    unsigned int ID;

    static std::string readFile(const std::string& filePath) {
        std::string content;
        std::ifstream fileStream(filePath, std::ios::in);
        if (!fileStream.is_open()) {return "";}
        std::stringstream sstr;
        sstr << fileStream.rdbuf();
        content = sstr.str();
        fileStream.close();
        return content;
    }

    static unsigned int compileShader(const unsigned int type, const char* source) {
        const unsigned int id = glCreateShader(type);
        glShaderSource(id, 1, &source, nullptr);
        glCompileShader(id);
        return id;
    }
public:
    Shader(const char* vertexPath, const char* fragmentPath) {
        const std::string vertexShaderCode = readFile(vertexPath);
        const char* vertexShaderSource = vertexShaderCode.c_str();
        // Вершинный шейдер выполняется для каждой вершины на экране, вычисляет финальные координаты точки
        const unsigned int vertex_shader = compileShader(GL_VERTEX_SHADER, vertexShaderSource);

        const std::string fragmentShaderCode = readFile(fragmentPath);
        const char* fragmentShaderSource = fragmentShaderCode.c_str();
        // Фрагментный шейдер выполнятеся для каждого фрагмента, определяет цвет конкретного пикселя
        const unsigned int fragment_shader = compileShader(GL_FRAGMENT_SHADER, fragmentShaderSource);

        this->ID = glCreateProgram();
        glAttachShader(this->ID, vertex_shader);
        glAttachShader(this->ID, fragment_shader);
        glLinkProgram(this->ID);
    }

    void use() const {
        glUseProgram(this->ID);
    }

    void setBool(const std::string &name, const bool value) const {
        glUniform1i(glGetUniformLocation(ID, name.c_str()), (int)value);
    }
    void setInt(const std::string &name, const  int value) const {
        glUniform1i(glGetUniformLocation(ID, name.c_str()), value);
    }
    void setFloat(const std::string &name, const  float value) const {
        glUniform1f(glGetUniformLocation(ID, name.c_str()), value);
    }
    void setVec2(const std::string &name, const  float x, const  float y) const {
        glUniform2f(glGetUniformLocation(ID, name.c_str()), x, y);
    }
    void setVec3(const std::string &name, const  float x, const  float y, const float z) const {
        glUniform3f(glGetUniformLocation(ID, name.c_str()), x, y, z);
    }

    void setMat3(const std::string &name, glm::mat3 camera) const {
        glUniformMatrix3fv(glGetUniformLocation(ID, name.c_str()), 1, GL_FALSE, glm::value_ptr(camera));
    }
};