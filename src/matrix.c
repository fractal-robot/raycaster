#include "matrix.h"
#include "structs.h"
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

Mat *createMat(int rows, int cols, bool initWithZero) {
  assert(rows > 0 && cols > 0);

  Mat *mat = malloc(sizeof(Mat));
  assert(mat != NULL);

  mat->rows = rows;
  mat->cols = cols;

  mat->data = malloc(rows * sizeof(float *));
  assert(mat->data != NULL);

  for (int i = 0; i < rows; ++i) {
    mat->data[i] = calloc(cols, sizeof(float));
    assert(mat->data[i] != NULL);
    if (initWithZero) {
      for (int j = 0; j < cols; ++j)
        mat->data[i][j] = 0.0;
    }
  }

  return mat;
}

void assignArray(Mat *mat, const float *values) {
  assert(mat != NULL && values != NULL);

  for (int i = 0; i < mat->rows; ++i)
    for (int j = 0; j < mat->cols; ++j)
      mat->data[i][j] = values[i * mat->cols + j];
}

void freeMat(Mat *matrix) {
  for (int i = 0; i < matrix->rows; ++i)
    free(matrix->data[i]);
  free(matrix->data);
  free(matrix);
}

bool isMatEmpty(const Mat *mat) {
  if (mat == NULL)
    return true;
  return (mat->rows == 0 || mat->cols == 0);
}

void setElement(Mat *mat, int row, int col, float value) {
  assert(mat != NULL && row >= 0 && row < mat->rows && col >= 0 &&
         col < mat->cols);
  mat->data[row][col] = value;
}

float getElement(const Mat *mat, int row, int col) {
  assert(mat != NULL && row >= 0 && row < mat->rows && col >= 0 &&
         col < mat->cols);
  return mat->data[row][col];
}

Mat *multiplyMat(const Mat *mat1, const Mat *mat2) {
  assert(mat1 != NULL && mat2 != NULL && mat1->cols == mat2->rows);

  Mat *result = createMat(mat1->rows, mat2->cols, false);
  assert(result != NULL);

  for (int i = 0; i < mat1->rows; ++i)
    for (int j = 0; j < mat2->cols; ++j)
      for (int k = 0; k < mat1->cols; ++k)
        result->data[i][j] += mat1->data[i][k] * mat2->data[k][j];

  return result;
}

void printMat(const Mat *matrix) {
  assert(matrix != NULL);

  printf("\n\n---\n");

  for (int i = 0; i < matrix->rows; ++i) {
    for (int j = 0; j < matrix->cols; ++j)
      printf("%10f", matrix->data[i][j]);
    printf("\n");
  }

  printf("\n---\n\n");
}

void normalizeMat(Mat *mat) {
  assert(mat != NULL && mat->cols == 1);

  float length = 0.0;
  for (int i = 0; i < mat->rows; ++i)
    length += mat->data[i][0] * mat->data[i][0];
  length = sqrt(length);

  for (int i = 0; i < mat->rows; ++i)
    mat->data[i][0] /= length;
}

Mat *crossMat(const Mat *u, const Mat *v) {
  assert(u != NULL && v != NULL && u->rows == 3 && v->rows == 3 &&
         u->cols == 1 && v->cols == 1);

  Mat *product = createMat(3, 1, false);
  assert(product != NULL);

  product->data[0][0] =
      u->data[1][0] * v->data[2][0] - u->data[2][0] * v->data[1][0];
  product->data[1][0] =
      u->data[2][0] * v->data[0][0] - u->data[0][0] * v->data[2][0];
  product->data[2][0] =
      u->data[0][0] * v->data[1][0] - u->data[1][0] * v->data[0][0];

  return product;
}

float dotProduct(const Mat *point, const Float3d plane) {
  assert(point != NULL && point->rows == 4 && point->cols == 1);

  return point->data[0][0] * plane.x + point->data[1][0] * plane.y +
         point->data[2][0] * plane.y;
}

Mat *subtractMat(const Mat *u, const Mat *v) {
  assert(u != NULL && v != NULL && u->rows == v->rows && u->cols == 1 &&
         v->cols == 1);

  Mat *subtracted = createMat(u->rows, 1, false);
  assert(subtracted != NULL);

  for (int i = 0; i < u->rows; ++i)
    subtracted->data[i][0] = u->data[i][0] - v->data[i][0];

  return subtracted;
}
