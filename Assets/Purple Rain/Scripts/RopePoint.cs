using System;
using System.Collections;
using System.Collections.Generic;
using GogoGaga.OptimizedRopesAndCables;
using UnityEngine;

[ExecuteAlways]
public class RopePoint : MonoBehaviour
{
    [SerializeField] Rope rope;

    [SerializeField][Range(0f, 1f)] float pointLocationOnRope = 0.1f;
    
    void Start()
    {
        UpdatePositionOnRope();
    }

    void Update()
    {
        if (Application.isPlaying)
        {
            UpdatePositionOnRope();
        }
    }

    void OnValidate()
    {
        UpdatePositionOnRope();
    }

    void UpdatePositionOnRope()
    {
        if (rope == null)
        {
            return;
        }

        Vector3 location = rope.GetPointAt(pointLocationOnRope);
        transform.position = location;
    }
}
