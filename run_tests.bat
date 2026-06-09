@echo off
echo ===================================================
echo Running GOTCHAA Test Suite with Coverage
echo ===================================================

echo.
echo [1/2] Running Unit and Widget Tests...
call flutter test --coverage

echo.
echo [2/2] Running Integration Tests...
call flutter test integration_test

echo.
echo ===================================================
echo Tests Completed.
echo Coverage report generated at coverage/lcov.info
echo ===================================================
