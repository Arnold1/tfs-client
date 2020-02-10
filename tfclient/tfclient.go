package tfclient

import (
	"errors"
	"sync"
	"time"
	"log"
	//"fmt"

	tfcore "github.com/Arnold1/tfs-client/proto/tensorflow/core/framework"
	tf "github.com/Arnold1/tfs-client/proto/tensorflow_serving/apis"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

type PredictionClient struct {
	mu      sync.RWMutex
	rpcConn *grpc.ClientConn
	svcConn tf.PredictionServiceClient
}

type Prediction struct {
	Class string  `json:"class"`
	Score float32 `json:"score"`
}

func NewClient(addr string) (*PredictionClient, error) {
	conn, err := grpc.Dial(addr, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	c := tf.NewPredictionServiceClient(conn)
	return &PredictionClient{rpcConn: conn, svcConn: c}, nil
}

func createHeaders(key string, val string) *metadata.MD {
	md := metadata.Pairs(
		key, val,
	)
	return &md
}

func (c *PredictionClient) Predict(modelName string) ([]Prediction, error) {
	// Create headers
	md := createHeaders("x-model-partition", "4-2")
	outCtx := metadata.NewOutgoingContext(context.Background(), *md)

	req := &tf.PredictRequest{
                ModelSpec: &tf.ModelSpec{
                        Name: modelName,
                },
                Inputs: map[string]*tfcore.TensorProto{
                        "height": &tfcore.TensorProto{
                                Dtype:       tfcore.DataType_DT_INT64,
                                Int64Val:    []int64{1},
                                TensorShape: &tfcore.TensorShapeProto{
                                        Dim: []*tfcore.TensorShapeProto_Dim{{Size: 1}},
                                },
                        },
                        "width": &tfcore.TensorProto{
                                Dtype:       tfcore.DataType_DT_INT64,
                                Int64Val:    []int64{1},
                                TensorShape: &tfcore.TensorShapeProto{
                                        Dim: []*tfcore.TensorShapeProto_Dim{{Size: 1}},
                                },
                        },
                },
        }

	start := time.Now()
	resp, err := c.svcConn.Predict(outCtx, req)
	if err != nil {
		return nil, err
	}
	elapsed := time.Since(start)
	log.Printf("Predict took %s", elapsed)

	//fmt.Println("resp:", resp)

	classesTensor, scoresTensor := resp.Outputs["classes"], resp.Outputs["scores"]
	if classesTensor == nil || scoresTensor == nil {
		return nil, errors.New("missing expected tensors in response")
	}

	classes := classesTensor.StringVal
	scores := scoresTensor.FloatVal
	var result []Prediction
	for i := 0; i < len(classes) && i < len(scores); i++ {
		result = append(result, Prediction{Class: string(classes[i]), Score: scores[i]})
	}
	return result, nil
}

func (c *PredictionClient) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.svcConn = nil
	return c.rpcConn.Close()
}
