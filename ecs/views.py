from django.shortcuts import render
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView


# Create your views here.


class Home(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        message = f"Hello from aws ecs"
        return Response({"message":message})