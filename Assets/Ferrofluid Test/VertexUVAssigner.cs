using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VertexUVAssigner : MonoBehaviour
{
    // Use this for initialization
    void Start () {
        Mesh mesh = gameObject.GetComponent<MeshFilter>().mesh;
        Vector3[] vertices = mesh.vertices;
        Vector2[] uv2s = new Vector2[vertices.Length];

        for (int i = 0; i < vertices.Length; i++)
        {
            uv2s[i] = new Vector2(i % 2, 0);
        }
        
        // foreach(Vector3 v in vertices){
        //     if(v.y>9.0f || v.y < 4.0){
        //         uv2s[i++] = new Vector2(2,0); 
        //     } else {
        //         uv2s[i++] = new Vector2(1,0);
        //     }
        // }
        mesh.uv2 = uv2s;
    }
}
