using System;
using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using Vector3 = UnityEngine.Vector3;

[ExecuteAlways]
public class ObjectSway : MonoBehaviour
{
    Vector3 initialRotation;

    [SerializeField] float rotationRate = 1f;
    [SerializeField] Vector3 rotationAxis = Vector3.up;
    [SerializeField] float rotationOffset = 30f;
    [SerializeField] float timeOffset = 0f;

    Vector3 desiredRotation;
    
    void Start()
    {
        initialRotation = transform.eulerAngles;
    }

    void OnEnable()
    {
        initialRotation = transform.eulerAngles;
    }

    void OnValidate()
    {
        //initialRotation = transform.eulerAngles;
    }

    [ExecuteInEditMode]
    void Update()
    {
        float rotationDelta = Mathf.Sin(Time.time * rotationRate + timeOffset) * rotationOffset;
        desiredRotation = initialRotation + rotationAxis * rotationDelta;

        transform.eulerAngles = desiredRotation;
    }
}
