#include <chrono>
#include <glm/glm.hpp>
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>

#include "Shader.cpp"

Shader* my_shader;
unsigned int VAO, VBO;

glm::vec3 cameraPos = glm::vec3(0, 0, -3);
glm::vec3 forward;
glm::vec3 right;
glm::vec3 up(0,1,0);
float lastX = 400, lastY = 300;
float yaw = -90.0f;
float pitch = 0.0f;
// float z_slice = -10;
float z_slice = 0;
int partial = 0;
bool firstMouse = true;

void init();
void render(GLFWwindow* window);
void processInput(GLFWwindow* window);
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void mouse_callback(GLFWwindow* window, double xposIn, double yposIn);
void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);

#include <iostream>
#include <GL/gl.h>

void printGPUInfo() {
    const GLubyte* vendor = glGetString(GL_VENDOR);
    const GLubyte* renderer = glGetString(GL_RENDERER);
    const GLubyte* version = glGetString(GL_VERSION);

    if (vendor) std::cout << "Vendor: " << vendor << std::endl;
    if (renderer) std::cout << "GPU: " << renderer << std::endl;
    if (version) std::cout << "OpenGL Version: " << version << std::endl;
}

float getTime() {
    static auto start_time = std::chrono::high_resolution_clock::now();
    auto current_time = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float> elapsed = current_time - start_time;
    return elapsed.count();
}

int main() {
    if (!glfwInit()) return -1;
    GLFWwindow* window = glfwCreateWindow(800, 600, "", NULL, NULL);
    if (!window) {glfwTerminate(); return -1;}
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetScrollCallback(window, scroll_callback);
    glfwSetKeyCallback(window, key_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

    glewInit();
    init();
    printGPUInfo();
    my_shader = new Shader("vertex_shader.glsl", "4D_frac.glsl");
    // my_shader = new Shader("vertex_shader.glsl", "surprise.glsl");
//    my_shader = new Shader("vertex_shader.glsl", "smooth_minimum.glsl");
    // my_shader = new Shader("vertex_shader.glsl", "mandelbulb.glsl");
    // my_shader = new Shader("vertex_shader.glsl", "fragment_shader.glsl");
    // my_shader = new Shader("vertex_shader.glsl", "mandelbox.glsl");
    while (!glfwWindowShouldClose(window)) {
        processInput(window);
        render(window);
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    delete my_shader;
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glfwTerminate();
    return 0;
}

void init() {
    float vertices[] = {
        -1.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0,

        -1.0, 1.0, 0.0,
        1.0, -1.0, 0.0,
        1.0, 1.0, 0.0,
    };
    // model = glm::mat4(1.0);

    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);

    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0,3, GL_FLOAT, GL_FALSE, 3*sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
}

void render(GLFWwindow* window) {
    glClear(GL_COLOR_BUFFER_BIT);
    my_shader->use();

    glm::vec3 up = glm::cross(right, forward);
    glm::mat3 viewMatrix = glm::mat3(right, up, forward);


    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    my_shader->setFloat("u_time", getTime() * 0.2f);
    my_shader->setVec2("u_resolution", (float)width, (float)height);
    my_shader->setVec3("u_camera_pos", cameraPos.x, cameraPos.y, cameraPos.z);
    my_shader->setMat3("u_camera", viewMatrix);
    my_shader->setFloat("u_zslice", z_slice);
    my_shader->setInt("partial", partial);

    glBindVertexArray(VAO);
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

void processInput(GLFWwindow* window) {
    // float cameraSpeed = 0.02f;
    float cameraSpeed = 0.002;
    if (glfwGetKey(window, GLFW_KEY_LEFT_CONTROL) == GLFW_PRESS)
        cameraSpeed *= 10;

    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);

    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        cameraPos += forward * cameraSpeed;
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        cameraPos -= forward * cameraSpeed;

    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        cameraPos -= right * cameraSpeed;
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        cameraPos += right * cameraSpeed;

    if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)
        cameraPos += up * cameraSpeed;
    if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS)
        cameraPos -= up * cameraSpeed;

    if (glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS)
        z_slice += 0.006;
    if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS)
        z_slice -= 0.006;
}

void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    if (key == GLFW_KEY_E && action == GLFW_PRESS) {
        partial = (partial == 0 ? 1 : 0);
    }
}

void mouse_callback(GLFWwindow* window, double xposIn, double yposIn) {
    float xpos = static_cast<float>(xposIn);
    float ypos = static_cast<float>(yposIn);

    if (firstMouse) {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }

    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos;
    lastX = xpos;
    lastY = ypos;

    float sensitivity = 0.1f;
    xoffset *= sensitivity;
    yoffset *= sensitivity;

    yaw += xoffset;
    pitch += yoffset;

    if (pitch > 89.0f) pitch = 89.0f;
    if (pitch < -89.0f) pitch = -89.0f;

    glm::vec3 f;
    f.x = cos(glm::radians(yaw)) * cos(glm::radians(pitch));
    f.y = sin(glm::radians(pitch));
    f.z = sin(glm::radians(yaw)) * cos(glm::radians(pitch));
    forward = glm::normalize(f);
    right = glm::normalize(glm::cross(forward, glm::vec3(0, 1, 0)));
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
    z_slice -= (float)yoffset/7.5;
    if (z_slice < -10.0f) z_slice = -10.0f;
    if (z_slice > 10.0f) z_slice = 10.0f;
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    glViewport(0,0,width, height);
}
